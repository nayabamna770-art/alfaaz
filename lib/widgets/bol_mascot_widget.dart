import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BolPose {
  welcoming,
  thoughtful,     // Stage 1 (Stuttering): thoughtful head-tilt pose
  handOnChest,    // Stage 2 (Confidence & Word-Finding): hand-on-chest pose
  hop,            // One-shot gesture: "Bol carries you forward"
  attentive,
  encouraging,
  celebrating,
  calm,
  emptyState,
}

// Backward compatibility alias for prior screen references
typedef BolState = BolPose;

class BolMascotWidget extends StatefulWidget {
  final BolPose pose;
  final double size;
  final bool showSoundwave;
  final bool isOneShot;
  final VoidCallback? onAnimationComplete;

  const BolMascotWidget({
    super.key,
    BolPose? pose,
    BolPose? state,
    this.size = 140,
    this.showSoundwave = true,
    this.isOneShot = false,
    this.onAnimationComplete,
  }) : pose = pose ?? state ?? BolPose.welcoming;

  @override
  State<BolMascotWidget> createState() => _BolMascotWidgetState();
}

class _BolMascotWidgetState extends State<BolMascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final duration = widget.pose == BolPose.hop
        ? const Duration(milliseconds: 650)
        : (widget.pose == BolPose.calm
            ? const Duration(seconds: 4)
            : const Duration(milliseconds: 1800));

    _controller = AnimationController(vsync: this, duration: duration);

    if (widget.isOneShot || widget.pose == BolPose.hop) {
      _controller.forward().then((_) {
        if (widget.onAnimationComplete != null) {
          widget.onAnimationComplete!();
        }
      });
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BolMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose) {
      _controller.dispose();
      _initController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BolProceduralPainter(
              pose: widget.pose,
              progress: _controller.value,
              showSoundwave: widget.showSoundwave,
            ),
          );
        },
      ),
    );
  }
}

class _BolProceduralPainter extends CustomPainter {
  final BolPose pose;
  final double progress;
  final bool showSoundwave;

  _BolProceduralPainter({
    required this.pose,
    required this.progress,
    required this.showSoundwave,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Vertical hop displacement for "Bol carries you forward"
    double hopOffsetY = 0;
    if (pose == BolPose.hop) {
      // Parabolic jump arc: up then down
      hopOffsetY = -math.sin(progress * math.pi) * (size.height * 0.22);
    }

    // Head tilt angle for thoughtful pose (Stage 1)
    double tiltAngle = 0;
    if (pose == BolPose.thoughtful) {
      tiltAngle = 0.12; // ~7 degrees thoughtful tilt
    } else if (pose == BolPose.handOnChest) {
      tiltAngle = -0.04; // subtle reassuring posture
    }

    final center = Offset(size.width / 2, size.height / 2 + hopOffsetY);
    final radius = size.width * 0.31;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);
    canvas.translate(-center.dx, -center.dy);

    // 1. Glowing Soundwave Prop (Signature prop per §5)
    if (showSoundwave && pose != BolPose.handOnChest && pose != BolPose.calm) {
      final wavePaint = Paint()
        ..color = AppColors.warmGolden.withValues(alpha: 0.25 + progress * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final waveRadius1 = radius + 12 + (progress * 6);
      final waveRadius2 = radius + 22 + (progress * 10);

      final waveRect1 = Rect.fromCircle(center: center, radius: waveRadius1);
      final waveRect2 = Rect.fromCircle(center: center, radius: waveRadius2);

      canvas.drawArc(waveRect1, -0.35, 0.7, false, wavePaint);
      canvas.drawArc(
        waveRect2,
        -0.25,
        0.5,
        false,
        wavePaint..strokeWidth = 2.0,
      );
    }

    // 2. Soft Ambient Glow
    final glowPaint = Paint()
      ..color = (pose == BolPose.calm ? AppColors.pinkBlush : AppColors.warmGolden)
          .withValues(alpha: 0.22 + progress * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, radius + 8, glowPaint);

    // 3. Bol's Body (Human-style, rounded friendly companion in Dark Olive)
    final faceColor =
        pose == BolPose.calm ? AppColors.deepMauve : AppColors.darkOlive;
    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    // 4. Warm blush cheeks
    final cheekPaint = Paint()
      ..color = AppColors.warmGolden.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final cheekY = center.dy + radius * 0.14;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.52, cheekY),
      radius * 0.16,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.52, cheekY),
      radius * 0.16,
      cheekPaint,
    );

    // 5. Eyes
    final eyePaint = Paint()
      ..color = AppColors.cream
      ..style = PaintingStyle.fill;

    final eyeY = center.dy - radius * 0.15;
    final eyeOffsetX = radius * 0.35;

    if (pose == BolPose.calm) {
      final eyeArcPaint = Paint()
        ..color = AppColors.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx - eyeOffsetX, eyeY),
          radius: radius * 0.12,
        ),
        0.2,
        math.pi - 0.4,
        false,
        eyeArcPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx + eyeOffsetX, eyeY),
          radius: radius * 0.12,
        ),
        0.2,
        math.pi - 0.4,
        false,
        eyeArcPaint,
      );
    } else if (pose == BolPose.thoughtful) {
      // Thoughtful eyes looking slightly up/reflective
      canvas.drawCircle(
        Offset(center.dx - eyeOffsetX, eyeY - 3),
        radius * 0.11,
        eyePaint,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeOffsetX, eyeY - 3),
        radius * 0.11,
        eyePaint,
      );
    } else {
      // Friendly open eyes
      canvas.drawCircle(
        Offset(center.dx - eyeOffsetX, eyeY),
        radius * 0.11,
        eyePaint,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeOffsetX, eyeY),
        radius * 0.11,
        eyePaint,
      );
    }

    // 6. Mouth
    final mouthPaint = Paint()
      ..color = AppColors.cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final mouthY = center.dy + radius * 0.28;

    if (pose == BolPose.hop || pose == BolPose.celebrating) {
      // Big open happy smile
      final mouthRect = Rect.fromCenter(
        center: Offset(center.dx, mouthY),
        width: radius * 0.65,
        height: radius * 0.38,
      );
      canvas.drawArc(mouthRect, 0.1, math.pi - 0.2, false, mouthPaint);
    } else if (pose == BolPose.thoughtful) {
      // Gentle thinking mouth
      final mouthRect = Rect.fromCenter(
        center: Offset(center.dx, mouthY),
        width: radius * 0.38,
        height: radius * 0.20,
      );
      canvas.drawArc(mouthRect, 0.1, math.pi - 0.2, false, mouthPaint);
    } else {
      // Warm curve
      final mouthRect = Rect.fromCenter(
        center: Offset(center.dx, mouthY),
        width: radius * 0.50,
        height: radius * 0.24,
      );
      canvas.drawArc(mouthRect, 0.1, math.pi - 0.2, false, mouthPaint);
    }

    // 7. Stage 2 Special Pose: Hand on Chest (Reassuring, calming posture)
    if (pose == BolPose.handOnChest) {
      final handPaint = Paint()
        ..color = AppColors.warmGolden
        ..style = PaintingStyle.fill;
      final handStroke = Paint()
        ..color = AppColors.deepCharcoal.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final handCenter = Offset(center.dx - radius * 0.15, center.dy + radius * 0.62);
      final handRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: handCenter, width: radius * 0.48, height: radius * 0.26),
        const Radius.circular(8),
      );
      canvas.drawRRect(handRect, handPaint);
      canvas.drawRRect(handRect, handStroke);

      final pulsePaint = Paint()
        ..color = AppColors.warmGolden.withValues(alpha: 0.3 + progress * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(handCenter, radius * 0.32 + progress * 4, pulsePaint);
    }

    // 8. Stage 1 Special Pose: Thoughtful Chin Touch
    if (pose == BolPose.thoughtful) {
      final handPaint = Paint()
        ..color = AppColors.warmGolden
        ..style = PaintingStyle.fill;
      final chinHandCenter = Offset(center.dx + radius * 0.45, center.dy + radius * 0.42);
      canvas.drawCircle(chinHandCenter, radius * 0.16, handPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BolProceduralPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pose != pose ||
        oldDelegate.showSoundwave != showSoundwave;
  }
}
