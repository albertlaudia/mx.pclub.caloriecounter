import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/animation/app_motion.dart';
import '../../core/theme/app_colors.dart';

/// Premium calorie progress ring — animated, gradient, with shimmer on overshoot.
///
/// Design notes:
/// - Outer track is muted, progress is brand gradient
/// - Center displays consumed / target with display typography
/// - Animated dasharray for buttery-smooth progress changes
/// - Subtle pulse on overshoot (small celebratory accent)
class CalorieRing extends StatefulWidget {
  const CalorieRing({
    super.key,
    required this.consumed,
    required this.target,
    this.size = 240,
    this.strokeWidth = 18,
    this.remainingLabel = 'remaining',
  });

  final double consumed;
  final double target;
  final double size;
  final double strokeWidth;
  final String remainingLabel;

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: AppMotion.slower,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progressAnimation = Tween<double>(begin: 0, end: widget.consumed / widget.target)
        .animate(CurvedAnimation(parent: _progressController, curve: AppMotion.emphasized));
    _progressController.forward();
  }

  @override
  void didUpdateWidget(CalorieRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consumed != widget.consumed) {
      _previousProgress = _progressAnimation.value;
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: (widget.consumed / widget.target).clamp(0.0, 1.5),
      ).animate(CurvedAnimation(parent: _progressController, curve: AppMotion.emphasized));
      _progressController
        ..reset()
        ..forward();

      // Pulse if overshoot
      if (widget.consumed > widget.target && oldWidget.consumed <= widget.target) {
        _pulseController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressAnimation, _pulseController]),
        builder: (context, _) {
          final progress = _progressAnimation.value.clamp(0.0, 1.0);
          final overshoot = _progressAnimation.value > 1.0;
          final pulseScale = overshoot
              ? 1.0 + (math.sin(_pulseController.value * math.pi * 2) * 0.02)
              : 1.0;

          return Transform.scale(
            scale: pulseScale,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                strokeWidth: widget.strokeWidth,
                overshoot: overshoot,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.consumed.round().toString(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${widget.target.round()} kcal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _RemainingPill(
                      remaining: (widget.target - widget.consumed).clamp(0, widget.target).toDouble(),
                      label: widget.remainingLabel,
                      overshoot: overshoot,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.overshoot,
  });
  final double progress;
  final double strokeWidth;
  final bool overshoot;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.surfaceMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc with gradient
    final progressPaint = Paint()
      ..shader = AppColors.brandGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Endpoint dot
    if (progress > 0) {
      final angle = -math.pi / 2 + sweepAngle;
      final dotOffset = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(dotOffset, strokeWidth / 2 + 2, dotPaint);

      final innerDotPaint = Paint()..color = overshoot ? AppColors.warning : AppColors.brand;
      canvas.drawCircle(dotOffset, strokeWidth / 2 - 4, innerDotPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.overshoot != overshoot;
}

class _RemainingPill extends StatelessWidget {
  const _RemainingPill({
    required this.remaining,
    required this.label,
    required this.overshoot,
  });
  final double remaining;
  final String label;
  final bool overshoot;

  @override
  Widget build(BuildContext context) {
    final color = overshoot ? AppColors.warning : AppColors.mint;
    final bgColor = overshoot ? const Color(0xFFFFF6E5) : AppColors.mintSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            overshoot ? 'over by ${(-remaining).round()}' : '${remaining.round()} $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}