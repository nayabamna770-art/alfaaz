import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';

class PracticeTestCardScreen extends StatefulWidget {
  const PracticeTestCardScreen({super.key});

  @override
  State<PracticeTestCardScreen> createState() => _PracticeTestCardScreenState();
}

class _PracticeTestCardScreenState extends State<PracticeTestCardScreen>
    with SingleTickerProviderStateMixin {
  // Hardcoded practice word
  static const String _wordUrdu = 'بول';
  static const String _wordEnglish = 'Bol';
  static const String _wordMeaning = 'Speak / Say';

  // Audio services
  late final FlutterTts _tts;
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  // Recording state
  bool _isRecording = false;
  bool _isTtsSpeaking = false;
  bool _isPlayingUserAudio = false;
  bool _isSaving = false;
  bool _hasSaved = false;
  String? _saveRating;

  String? _recordedAudioPath;
  Uint8List? _recordedAudioBytes;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;
  List<double> _amplitudeBars = List.filled(9, 0.15);

  String? _statusMessage;
  bool _micPermissionDenied = false;

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';

  @override
  void initState() {
    super.initState();
    _initTts();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    // Listen to just_audio player state for user playback
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingUserAudio = state.playing &&
              state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
            _isPlayingUserAudio = false;
          }
        });
      }
    });
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.42); // Deliberate, clear cadence for practice

      _tts.setStartHandler(() {
        if (mounted) setState(() => _isTtsSpeaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isTtsSpeaking = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _isTtsSpeaking = false);
      });
    } catch (e) {
      debugPrint('[DEBUG_PRACTICE] TTS init error: $e');
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    _tts.stop();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── TTS Guide ─────────────────────────────────────────────────────────────

  Future<void> _playTtsGuide() async {
    if (_isTtsSpeaking) {
      await _tts.stop();
      setState(() => _isTtsSpeaking = false);
      return;
    }

    try {
      if (_isUrdu) {
        final langs = await _tts.getLanguages;
        if (langs != null &&
            (langs.contains('ur') ||
                langs.contains('ur-PK') ||
                langs.contains('ur_PK'))) {
          await _tts.setLanguage('ur-PK');
          await _tts.speak(_wordUrdu);
          return;
        }
      }
      await _tts.setLanguage('en-US');
      await _tts.speak(_wordEnglish);
    } catch (e) {
      debugPrint('[DEBUG_PRACTICE] TTS speak error: $e');
      setState(() => _isTtsSpeaking = false);
    }
  }

  // ── Recording Flow ────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _micPermissionDenied = true;
          _statusMessage = _isUrdu
              ? 'براہ کرم مائیکروفون کی اجازت دیں۔'
              : 'Please allow microphone access to practice.';
        });
        return;
      }

      setState(() {
        _micPermissionDenied = false;
        _statusMessage = null;
        _isRecording = true;
        _recordingSeconds = 0;
        _recordedAudioPath = null;
        _recordedAudioBytes = null;
        _hasSaved = false;
        _saveRating = null;
      });

      String targetPath = '';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        targetPath =
            '${dir.path}/practice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: targetPath,
      );

      // Start duration counter
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _isRecording) {
          setState(() => _recordingSeconds++);
        }
      });

      // Start amplitude polling for live waveform
      _amplitudeTimer =
          Timer.periodic(const Duration(milliseconds: 90), (_) async {
        if (!mounted || !_isRecording) return;
        try {
          final amp = await _audioRecorder.getAmplitude();
          final currentDb = amp.current; // -160 to 0
          // Normalize to range 0.15 .. 1.0
          final normalized = ((currentDb + 50) / 50).clamp(0.15, 1.0);
          final random = Random();

          setState(() {
            _amplitudeBars = List.generate(9, (i) {
              final variation = (random.nextDouble() * 0.25) - 0.12;
              return (normalized + variation).clamp(0.15, 1.0);
            });
          });
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('[DEBUG_PRACTICE] Start recording error: $e');
      setState(() {
        _isRecording = false;
        _statusMessage = _isUrdu
            ? 'ریکارڈنگ شروع نہیں ہو سکی۔ دوبارہ کوشش کریں۔'
            : 'Could not start recording. Please try again.';
      });
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();

    try {
      final path = await _audioRecorder.stop();
      Uint8List? bytes;

      if (path != null && path.isNotEmpty) {
        if (!kIsWeb) {
          final file = File(path);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
          }
        }
      }

      setState(() {
        _isRecording = false;
        _recordedAudioPath = path;
        _recordedAudioBytes = bytes;
        _amplitudeBars = List.filled(9, 0.15);
      });
    } catch (e) {
      debugPrint('[DEBUG_PRACTICE] Stop recording error: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  // ── User Audio Playback ───────────────────────────────────────────────────

  Future<void> _playUserRecording() async {
    if (_recordedAudioPath == null) return;

    if (_isPlayingUserAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingUserAudio = false);
      return;
    }

    try {
      if (kIsWeb) {
        await _audioPlayer.setUrl(_recordedAudioPath!);
      } else {
        await _audioPlayer.setFilePath(_recordedAudioPath!);
      }
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('[DEBUG_PRACTICE] Playback error: $e');
      setState(() => _isPlayingUserAudio = false);
    }
  }

  // ── Self-Rating & Supabase Storage + Database Save ────────────────────────

  Future<void> _handleRating(String rating) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _saveRating = rating;
      _statusMessage = null;
    });

    final userId = SupabaseService.currentUserId;
    String? storagePath;

    // 1. Upload audio bytes to Supabase Storage bucket 'practice-recordings'
    if (_recordedAudioBytes != null && userId != null) {
      storagePath = await SupabaseService.uploadPracticeRecording(
        userId: userId,
        audioBytes: _recordedAudioBytes!,
        fileExtension: 'm4a',
      );
    }

    // 2. Insert practice session row in database
    await SupabaseService.savePracticeSession(
      userId: userId,
      selfRating: rating,
      recordingUrl: storagePath ?? _recordedAudioPath,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _hasSaved = true;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _isUrdu ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
              color: AppColors.deepCharcoal,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _isUrdu
                ? AppStrings.practiceTestTitleUr
                : AppStrings.practiceTestTitleEn,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: BolMascotWidget(
                state: BolState.attentive,
                size: 38,
                showSoundwave: false,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Target Word Card ───────────────────────────────────────
                _buildWordCard(),
                const SizedBox(height: 18),

                // ── Status / Permission Banner (if any) ──────────────────────
                if (_statusMessage != null) ...[
                  _buildStatusBanner(_statusMessage!,
                      isError: _micPermissionDenied),
                  const SizedBox(height: 14),
                ],

                // ── 2. Step 1: Listen (TTS Model Guide) ──────────────────────
                _buildListenSection(),
                const SizedBox(height: 18),

                // ── 3. Step 2: Record Your Voice ─────────────────────────────
                _buildRecordSection(),
                const SizedBox(height: 18),

                // ── 4. Step 3: Compare & Playback Clips ──────────────────────
                if (_recordedAudioPath != null && !_isRecording) ...[
                  _buildPlaybackComparisonSection(),
                  const SizedBox(height: 20),

                  // ── 5. Step 4: Self-Rating & Save ──────────────────────────
                  _buildRatingSection(),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── UI Components ─────────────────────────────────────────────────────────

  Widget _buildWordCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warmGolden.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isUrdu ? 'واحد لفظ کی مشق' : 'Single Word Practice',
              style: const TextStyle(
                color: AppColors.deepCharcoal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Big Urdu Word
          const Text(
            _wordUrdu,
            style: TextStyle(
              color: AppColors.darkOlive,
              fontSize: 52,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),

          // Transliteration / English
          const Text(
            _wordEnglish,
            style: TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),

          // Meaning / Hint
          Text(
            _isUrdu ? 'بولنا یا کہنا' : _wordMeaning,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListenSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.darkOlive,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '1',
                  style: TextStyle(
                    color: AppColors.cream,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isUrdu ? 'پہلا مرحلہ: سنیں' : 'Step 1: Listen',
                style: const TextStyle(
                  color: AppColors.deepCharcoal,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isUrdu
                ? 'لفظ کی درست آواز سنیں تاکہ آپ اعتماد سے بول سکیں۔'
                : 'Listen to the clear pronunciation before you speak.',
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Large Listen Button (min 48 height)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _playTtsGuide,
              icon: Icon(
                _isTtsSpeaking
                    ? Icons.volume_up_rounded
                    : Icons.volume_up_outlined,
                size: 24,
              ),
              label: Text(
                _isTtsSpeaking
                    ? (_isUrdu ? 'آواز جاری ہے...' : 'Speaking word...')
                    : (_isUrdu
                        ? AppStrings.listenWordBtnUr
                        : AppStrings.listenWordBtnEn),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkOlive,
                foregroundColor: AppColors.cream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRecording ? AppColors.darkOlive : AppColors.borderCharcoal,
          width: _isRecording ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.darkOlive,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: AppColors.cream,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isUrdu ? 'دوسرا مرحلہ: بولیں' : 'Step 2: Speak & Record',
                style: const TextStyle(
                  color: AppColors.deepCharcoal,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isUrdu
                ? 'مائیکروفون کا بٹن دبائیں اور اپنا تلفظ ریکارڈ کریں۔'
                : 'Tap to record your voice. Say "Bol" clearly at your own pace.',
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Recording active state with live waveform
          if (_isRecording) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkOlive),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC62828),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '00:${_recordingSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: AppColors.deepCharcoal,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Live dynamic waveform bars
                  SizedBox(
                    height: 42,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _amplitudeBars.map((level) {
                        return Container(
                          width: 6,
                          height: (level * 40).clamp(6.0, 40.0),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.darkOlive,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stop recording button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop_rounded, size: 24),
                label: Text(
                  _isUrdu
                      ? AppStrings.stopRecordingBtnUr
                      : AppStrings.stopRecordingBtnEn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ] else ...[
            // Start recording button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic_rounded, size: 24),
                label: Text(
                  _isUrdu
                      ? AppStrings.recordVoiceBtnUr
                      : AppStrings.recordVoiceBtnEn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkOlive,
                  foregroundColor: AppColors.cream,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaybackComparisonSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.darkOlive,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: AppColors.cream,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isUrdu ? 'تیسرا مرحلہ: موازنہ کریں' : 'Step 3: Listen & Compare',
                style: const TextStyle(
                  color: AppColors.deepCharcoal,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Clip A: TTS Model Guide
          _buildAudioClipTile(
            title: _isUrdu
                ? AppStrings.ttsGuideClipUr
                : AppStrings.ttsGuideClipEn,
            subtitle: _isUrdu ? 'صحیح رہنما آواز' : 'Model pronunciation',
            isPlaying: _isTtsSpeaking,
            icon: Icons.record_voice_over_rounded,
            onTap: _playTtsGuide,
          ),
          const SizedBox(height: 10),

          // Clip B: User Recording
          _buildAudioClipTile(
            title: _isUrdu
                ? AppStrings.yourRecordingClipUr
                : AppStrings.yourRecordingClipEn,
            subtitle: _isUrdu ? 'آپ کی ریکارڈ شدہ آواز' : 'Your spoken audio',
            isPlaying: _isPlayingUserAudio,
            icon: Icons.mic_external_on_rounded,
            onTap: _playUserRecording,
          ),
          const SizedBox(height: 8),

          // Re-record button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.replay_rounded,
                  size: 18, color: AppColors.darkOlive),
              label: Text(
                _isUrdu ? AppStrings.reRecordBtnUr : AppStrings.reRecordBtnEn,
                style: const TextStyle(
                  color: AppColors.darkOlive,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioClipTile({
    required String title,
    required String subtitle,
    required bool isPlaying,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppColors.darkOlive.withValues(alpha: 0.12)
              : AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying ? AppColors.darkOlive : AppColors.borderCharcoal,
            width: isPlaying ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: AppColors.darkOlive,
              size: 38,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.deepCharcoal,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.mutedCharcoal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              color: AppColors.mutedCharcoal,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    if (_hasSaved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.warmGolden.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.warmGolden),
        ),
        child: Row(
          children: [
            const BolMascotWidget(
              state: BolState.celebrating,
              size: 48,
              showSoundwave: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isUrdu
                        ? AppStrings.savedConfirmationUr
                        : AppStrings.savedConfirmationEn,
                    style: const TextStyle(
                      color: AppColors.deepCharcoal,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isUrdu
                        ? 'آپ کی ریکارڈنگ محفوظ ہو چکی ہے۔'
                        : 'Saved to Supabase with rating: $_saveRating',
                    style: const TextStyle(
                      color: AppColors.mutedCharcoal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.darkOlive,
              size: 26,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.darkOlive,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '4',
                  style: TextStyle(
                    color: AppColors.cream,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isUrdu
                    ? AppStrings.howDidItFeelUr
                    : AppStrings.howDidItFeelEn,
                style: const TextStyle(
                  color: AppColors.deepCharcoal,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isUrdu
                ? 'اپنے تجربے کا انتخاب کریں تاکہ آپ کی پیش رفت محفوظ ہو سکے۔'
                : 'Select how it felt to save your session to Supabase.',
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          if (_isSaving) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.darkOlive),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Saving recording & session...',
                      style: TextStyle(
                        color: AppColors.mutedCharcoal,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Two large rating buttons (min height 50)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleRating('easy'),
                      icon: const Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: AppColors.darkOlive,
                        size: 22,
                      ),
                      label: Text(
                        _isUrdu ? AppStrings.feltEasyUr : AppStrings.feltEasyEn,
                        style: const TextStyle(
                          color: AppColors.darkOlive,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.darkOlive, width: 1.5),
                        backgroundColor: AppColors.cream,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleRating('hard'),
                      icon: const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.darkOlive,
                        size: 20,
                      ),
                      label: Text(
                        _isUrdu ? AppStrings.feltHardUr : AppStrings.feltHardEn,
                        style: const TextStyle(
                          color: AppColors.darkOlive,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.darkOlive, width: 1.5),
                        backgroundColor: AppColors.cream,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String message, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFECEC) : AppColors.creamSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError ? const Color(0xFFE57373) : AppColors.borderCharcoal,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.mic_off_rounded : Icons.info_outline_rounded,
            color: isError ? const Color(0xFFC62828) : AppColors.darkOlive,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError
                    ? const Color(0xFFC62828)
                    : AppColors.deepCharcoal,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
