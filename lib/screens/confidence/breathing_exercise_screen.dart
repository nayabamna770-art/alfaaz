import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';

/// Guided box-breathing exercise opened from the "Breathing" card in the
/// Confidence tab.
///
/// One cycle = inhale 4s -> hold 4s -> exhale 4s -> hold 4s (16s total),
/// repeated 4 times. After the last cycle a short "How do you feel?"
/// self-check is shown, and "Done" returns to the Confidence menu.
///
/// No recording or mic permission is involved.
class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  // Hardcoded hex values reused from the Confidence menu (no new colors):
  // 1. Screen background cream: #FFFDF5
  // 2. Olive accent: #556B2F
  // 3. Light olive tint: #E8EEDC
  // 4. Muted cream/olive badge tone: #E2E7D5
  static const Color _screenBg = Color(0xFFFFFDF5);
  static const Color _oliveAccent = Color(0xFF556B2F);
  static const Color _oliveTint = Color(0xFFE8EEDC);
  static const Color _badgeTone = Color(0xFFE2E7D5);

  static const int _totalCycles = 4;
  static const int _phaseSeconds = 4;
  static const double _cycleSeconds = _phaseSeconds * 4; // 16s per cycle
  static const double _sessionSeconds = _cycleSeconds * _totalCycles; // 64s

  /// Runs all 4 cycles back to back so the breath never stutters between them.
  late final AnimationController _controller;

  /// Independent slow pulse for the soft glow around the circle.
  late final AnimationController _glowController;

  bool _showSelfCheck = false;
  int? _selectedFeeling; // 0 = calm/good, 1 = neutral/okay

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _phaseSeconds * 4 * _totalCycles),
    )..addStatusListener(_onSessionStatus);

    _controller.forward();
  }

  void _onSessionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _glowController.stop();
    setState(() => _showSelfCheck = true);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onSessionStatus);
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Cycle math
  // ---------------------------------------------------------------------------

  /// Index of the cycle in progress (0..3).
  int _cycleIndex(double t) {
    return (t * _sessionSeconds / _cycleSeconds)
        .floor()
        .clamp(0, _totalCycles - 1);
  }

  /// Seconds elapsed inside the current cycle (0..16).
  double _cycleElapsed(double t) {
    return (t * _sessionSeconds - _cycleIndex(t) * _cycleSeconds)
        .clamp(0.0, _cycleSeconds);
  }

  /// 0 = breathe in, 1 = hold, 2 = breathe out, 3 = hold.
  int _phaseIndex(double t) {
    return (_cycleElapsed(t) / _phaseSeconds).floor().clamp(0, 3);
  }

  /// Seconds elapsed inside the current phase (0..4).
  double _phaseElapsed(double t) {
    return (_cycleElapsed(t) - _phaseIndex(t) * _phaseSeconds)
        .clamp(0.0, _phaseSeconds.toDouble());
  }

  /// Countdown shown to the user: 4 -> 3 -> 2 -> 1.
  int _countdown(double t) {
    return (_phaseSeconds - _phaseElapsed(t)).ceil().clamp(1, _phaseSeconds);
  }

  /// Eased 0..1 "expansion" of the breath: 0 fully contracted, 1 fully expanded.
  double _expansion(double t) {
    final phase = _phaseIndex(t);
    final progress = (_phaseElapsed(t) / _phaseSeconds).clamp(0.0, 1.0);
    switch (phase) {
      case 0: // inhale: grow
        return Curves.easeInOutSine.transform(progress);
      case 1: // hold in: stay expanded
        return 1.0;
      case 2: // exhale: shrink
        return 1.0 - Curves.easeInOutSine.transform(progress);
      default: // hold out: stay contracted
        return 0.0;
    }
  }

  String _phaseLabel(int phase) {
    switch (phase) {
      case 0:
        return _isUrdu ? 'سانس اندر لیں' : 'Breathe in';
      case 2:
        return _isUrdu ? 'سانس باہر نکالیں' : 'Breathe out';
      default:
        return _isUrdu ? 'روکیں' : 'Hold';
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _screenBg,
        body: AnimatedBuilder(
          animation: Listenable.merge([_controller, _glowController]),
          builder: (context, _) {
            final t = _controller.value;
            final expansion = _showSelfCheck ? 0.0 : _expansion(t);

            // Slow ambient gradient shift: drifts out and back over each cycle
            // so the background never jumps between cycles.
            final drift =
                (1 - math.cos(_cycleElapsed(t) / _cycleSeconds * 2 * math.pi)) /
                    2;
            final topColor = Color.lerp(
              _screenBg,
              _oliveTint,
              0.12 + drift * 0.40,
            )!;
            final bottomColor = Color.lerp(
              _screenBg,
              _badgeTone,
              0.04 + drift * 0.22,
            )!;

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _showSelfCheck
                      ? const [_screenBg, _oliveTint]
                      : [topColor, bottomColor],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _showSelfCheck
                          ? _buildSelfCheck()
                          : _buildBreathingBody(t, expansion),
                    ),
                  ],
                ),
              ),
            );
          },
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
              color: _oliveAccent,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              _isUrdu ? 'سانس کی مشق' : 'Breathing',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _oliveAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48), // balances the leading icon button
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Breathing view
  // ---------------------------------------------------------------------------

  Widget _buildBreathingBody(double t, double expansion) {
    final phase = _phaseIndex(t);
    final countdown = _countdown(t);
    final pulse = _glowController.value;

    // Circle scale: contracted 0.62 -> expanded 1.0 of its 220px box.
    final circleScale = 0.62 + expansion * 0.38;
    // Bol breathes with the circle, but more gently.
    final mascotScale = 0.90 + expansion * 0.22;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            // Fits the 220px circle at full expansion plus its 1.16x halo.
            height: 260,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer halo ring that pulses softly out of phase.
                  Transform.scale(
                    scale: circleScale * (1.10 + pulse * 0.06),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _oliveAccent.withValues(
                            alpha: 0.10 + expansion * 0.12,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // Breathing circle with a soft glow.
                  Transform.scale(
                    key: const ValueKey('breathing-circle'),
                    scale: circleScale,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color.lerp(_oliveTint, _screenBg, 0.35)!,
                            Color.lerp(_oliveTint, _oliveAccent, 0.16)!,
                          ],
                        ),
                        border: Border.all(
                          color: _oliveAccent.withValues(
                            alpha: 0.22 + expansion * 0.16,
                          ),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _oliveAccent.withValues(
                              alpha: 0.10 + expansion * 0.12 + pulse * 0.05,
                            ),
                            blurRadius: 28 + expansion * 26 + pulse * 8,
                            spreadRadius: 2 + expansion * 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bol scales in sync with the breath.
                  Transform.scale(
                    key: const ValueKey('breathing-mascot'),
                    scale: mascotScale,
                    child: const BolMascotWidget(
                      pose: BolPose.calm,
                      size: 118,
                      showSoundwave: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Phase label fades whenever the phase changes.
          SizedBox(
            height: 34,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              child: Text(
                _phaseLabel(phase),
                key: ValueKey<int>(phase),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _oliveAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 4 - 3 - 2 - 1 countdown, fading on every tick.
          SizedBox(
            height: 44,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: Text(
                '$countdown',
                key: ValueKey<String>('$phase-$countdown'),
                style: TextStyle(
                  color: _oliveAccent.withValues(alpha: 0.75),
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          _buildCycleIndicator(_cycleIndex(t)),
          const SizedBox(height: 10),
          Text(
            _isUrdu
                ? 'آرام سے بیٹھیں اور دائرے کے ساتھ سانس لیں۔'
                : 'Sit comfortably and follow the circle with your breath.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCycleIndicator(int cycleIndex) {
    final current = cycleIndex + 1;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(_totalCycles, (index) {
            final isDone = index < cycleIndex;
            final isCurrent = index == cycleIndex;
            return Container(
              width: isCurrent ? 12 : 8,
              height: isCurrent ? 12 : 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isCurrent
                    ? _oliveAccent.withValues(alpha: isCurrent ? 0.9 : 0.45)
                    : _badgeTone,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _isUrdu ? 'دور $current / $_totalCycles' : 'Cycle $current of $_totalCycles',
          style: TextStyle(
            color: _oliveAccent.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Self-check view
  // ---------------------------------------------------------------------------

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
              color: _oliveAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isUrdu
                ? 'چار دور مکمل ہو گئے۔ بہت خوب!'
                : 'You completed all 4 breathing cycles. Well done!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildFeelingOption(
                  index: 0,
                  emoji: '🙂',
                  label: _isUrdu ? 'پرسکون' : 'Calmer',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFeelingOption(
                  index: 1,
                  emoji: '😐',
                  label: _isUrdu ? 'ٹھیک' : 'About the same',
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
                backgroundColor: _oliveAccent,
                foregroundColor: _screenBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _isUrdu ? 'مکمل' : 'Done',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeelingOption({
    required int index,
    required String emoji,
    required String label,
  }) {
    final isSelected = _selectedFeeling == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFeeling = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _oliveTint : _screenBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? _oliveAccent
                : _oliveAccent.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _oliveAccent,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
