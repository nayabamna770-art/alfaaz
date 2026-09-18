import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';

/// A narrated visualization exercise selected for the learner's age group.
class VisualizationExerciseScreen extends StatefulWidget {
  const VisualizationExerciseScreen({super.key});

  @override
  State<VisualizationExerciseScreen> createState() =>
      _VisualizationExerciseScreenState();
}

class _VisualizationExerciseScreenState
    extends State<VisualizationExerciseScreen>
    with TickerProviderStateMixin {
  static String? _lastScriptKey;

  final FlutterTts _tts = FlutterTts();
  late final AnimationController _sceneController;
  late final AnimationController _pulseController;

  Map<String, dynamic>? _script;
  bool _isLoading = true;
  bool _isNarrating = false;
  bool _showSelfCheck = false;
  int? _selectedFeeling;
  String? _errorMessage;
  Completer<void>? _narrationCompleter;

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';
  String get _scriptType => _script?['script_type'] as String? ?? 'safe_place';

  @override
  void initState() {
    super.initState();
    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _loadScript();
  }

  Future<void> _loadScript() async {
    try {
      final userId = SupabaseService.currentUserId;
      final profile = userId == null
          ? null
          : await SupabaseService.getUserProfile(userId);
      final age = profile?.age;
      final ageGroup = age == null
          ? 'adult'
          : age <= 4
          ? 'early'
          : age <= 12
          ? 'child'
          : age <= 17
          ? 'teen'
          : 'adult';

      final rows = await SupabaseService.client
          .from('visualization_scripts')
          .select()
          .eq('age_group', ageGroup);
      final scripts = List<Map<String, dynamic>>.from(rows as List);
      if (scripts.isEmpty) {
        throw StateError('No visualization script is available.');
      }

      final available = scripts.where((row) {
        final key = (row['id'] ?? row['text_en'] ?? row['text_ur']).toString();
        return key != _lastScriptKey || scripts.length == 1;
      }).toList();
      final selected =
          (available.isEmpty ? scripts : available)[math.Random().nextInt(
            (available.isEmpty ? scripts : available).length,
          )];
      _lastScriptKey =
          (selected['id'] ?? selected['text_en'] ?? selected['text_ur'])
              .toString();

      if (!mounted) return;
      setState(() {
        _script = selected;
        _isLoading = false;
      });
      await _startNarration();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _isUrdu
            ? 'مشق لوڈ نہیں ہو سکی۔ دوبارہ کوشش کریں۔'
            : 'This exercise could not be loaded. Please try again.';
      });
      debugPrint('[DEBUG_VISUALIZATION] Load error: $error');
    }
  }

  Future<void> _startNarration() async {
    final script = _script;
    if (script == null) return;

    final text = (_isUrdu ? script['text_ur'] : script['text_en']) as String?;
    if (text == null || text.trim().isEmpty) {
      if (mounted) setState(() => _showSelfCheck = true);
      return;
    }

    _narrationCompleter = Completer<void>();
    _tts.setStartHandler(() {
      if (mounted) setState(() => _isNarrating = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isNarrating = false;
          _showSelfCheck = true;
        });
      }
      if (!(_narrationCompleter?.isCompleted ?? true)) {
        _narrationCompleter!.complete();
      }
    });
    _tts.setErrorHandler((_) {
      if (mounted) {
        setState(() {
          _isNarrating = false;
          _showSelfCheck = true;
        });
      }
      if (!(_narrationCompleter?.isCompleted ?? true)) {
        _narrationCompleter!.complete();
      }
    });

    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.42);
      await _tts.setLanguage(_isUrdu ? 'ur-PK' : 'en-US');
      if (mounted) setState(() => _isNarrating = true);
      await _tts.speak(text);
      await _narrationCompleter!.future;
    } catch (error) {
      debugPrint('[DEBUG_VISUALIZATION] TTS error: $error');
      if (mounted) {
        setState(() {
          _isNarrating = false;
          _showSelfCheck = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _sceneController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.darkOlive,
                          ),
                        ),
                      )
                    : _errorMessage != null
                    ? _buildError()
                    : _showSelfCheck
                    ? _buildSelfCheck()
                    : _buildNarrationView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isUrdu
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
              color: AppColors.darkOlive,
              size: 20,
            ),
            onPressed: _isNarrating ? null : () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              _isUrdu ? 'تصوراتی مشق' : 'Visualization',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkOlive,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNarrationView() {
    final scriptText = _script == null
        ? ''
        : (_script![_isUrdu ? 'text_ur' : 'text_en'] as String? ?? '');
    return AnimatedBuilder(
      animation: Listenable.merge([_sceneController, _pulseController]),
      builder: (context, _) {
        final t = _sceneController.value;
        final pulse = _pulseController.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 10),
              SizedBox(height: 330, child: _buildScene(t, pulse)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.creamSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderCharcoal),
                ),
                child: Text(
                  scriptText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.deepCharcoal,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isUrdu ? 'آرام سے سنیں اور تصور کریں' : 'Listen and imagine',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.darkOlive,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isUrdu
                    ? 'بولنے کی اس پرسکون تصویر کو اپنے ذہن میں جگہ دیں۔'
                    : 'Let this calm picture of speaking settle in your mind.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.mutedCharcoal,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.darkOlive,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScene(double t, double pulse) {
    switch (_scriptType) {
      case 'light_rehearsal':
        return _buildFigureScene(
          background: const [Color(0xFFF6E9D8), Color(0xFFE8EEDC)],
          glow: AppColors.warmGolden,
          pulse: 0.08 + pulse * 0.08,
        );
      case 'real_rehearsal':
        return _buildFigureScene(
          background: const [Color(0xFFDCE5E2), Color(0xFFEDE8D9)],
          glow: AppColors.warmGolden,
          pulse: 0.10 + pulse * 0.13,
        );
      default:
        return _buildSafePlaceScene(t);
    }
  }

  Widget _buildSafePlaceScene(double t) {
    final drift = math.sin(t * math.pi * 2);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFDDB5), Color(0xFFE8EEDC)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: 34,
              left: 34,
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFFFFF2BD), Color(0xFFE8A94B)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 90 + drift * 8,
              left: 136 + drift * 12,
              child: _cloud(82),
            ),
            Positioned(
              top: 152 - drift * 6,
              right: 32 - drift * 12,
              child: _cloud(64),
            ),
            Positioned(
              bottom: 42 + drift * 5,
              left: 30 - drift * 10,
              child: _cloud(54),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 76,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB9C99E), Color(0xFFE8EEDC)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 52,
              left: 0,
              right: 0,
              child: BolMascotWidget(
                pose: BolPose.calm,
                size: 112,
                showSoundwave: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cloud(double width) {
    return SizedBox(
      width: width,
      height: width * 0.42,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: width * 0.25,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Positioned(
            bottom: width * 0.10,
            left: width * 0.18,
            child: _cloudBump(width * 0.34),
          ),
          Positioned(
            bottom: width * 0.09,
            right: width * 0.17,
            child: _cloudBump(width * 0.42),
          ),
        ],
      ),
    );
  }

  Widget _cloudBump(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFigureScene({
    required List<Color> background,
    required Color glow,
    required double pulse,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: background,
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 210 + pulse * 50,
              height: 210 + pulse * 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: pulse),
                    blurRadius: 38,
                    spreadRadius: 18,
                  ),
                ],
              ),
            ),
            _buildCalmFigure(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalmFigure() {
    return SizedBox(
      width: 150,
      height: 240,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFF6B625B),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: 66,
            child: Container(
              width: 88,
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.darkOlive.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(44),
              ),
            ),
          ),
          Positioned(
            top: 78,
            left: 14,
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                width: 16,
                height: 106,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B625B).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            top: 78,
            right: 14,
            child: Transform.rotate(
              angle: 0.22,
              child: Container(
                width: 16,
                height: 106,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B625B).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 47,
            child: Container(
              width: 16,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF6B625B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 47,
            child: Container(
              width: 16,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF6B625B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.darkOlive,
              size: 56,
            ),
            const SizedBox(height: 18),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedCharcoal,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfCheck() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const BolMascotWidget(
            pose: BolPose.calm,
            size: 120,
            showSoundwave: false,
          ),
          const SizedBox(height: 20),
          Text(
            _isUrdu ? 'آپ کیسا محسوس کر رہے ہیں؟' : 'How do you feel?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.darkOlive,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildFeelingOption(
                  0,
                  '🙂',
                  _isUrdu ? 'پرسکون' : 'Calmer',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFeelingOption(
                  1,
                  '😐',
                  _isUrdu ? 'ٹھیک' : 'About the same',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkOlive,
                foregroundColor: AppColors.cream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isUrdu ? 'مکمل' : 'Done',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingOption(int index, String emoji, String label) {
    final selected = _selectedFeeling == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFeeling = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkOlive : AppColors.creamSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.darkOlive : AppColors.borderCharcoal,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppColors.cream : AppColors.deepCharcoal,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
