import 'package:flutter/material.dart';
import '../../core/animation/app_motion.dart';
import '../../core/theme/app_colors.dart';

/// Animated macro breakdown bar — protein / carbs / fat in one elegant strip.
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  @override
  Widget build(BuildContext context) {
    final proteinKcal = proteinGrams * 4;
    final carbsKcal = carbsGrams * 4;
    final fatKcal = fatGrams * 9;
    final total = (proteinKcal + carbsKcal + fatKcal).clamp(1, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                _AnimatedSegment(
                  flex: proteinKcal / total,
                  color: AppColors.lavender,
                  delay: Duration.zero,
                ),
                _AnimatedSegment(
                  flex: carbsKcal / total,
                  color: AppColors.sky,
                  delay: const Duration(milliseconds: 100),
                ),
                _AnimatedSegment(
                  flex: fatKcal / total,
                  color: AppColors.rose,
                  delay: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Legend
        Row(
          children: [
            _MacroLegend(
              label: 'Protein',
              grams: proteinGrams,
              color: AppColors.lavender,
            ),
            const SizedBox(width: 16),
            _MacroLegend(
              label: 'Carbs',
              grams: carbsGrams,
              color: AppColors.sky,
            ),
            const SizedBox(width: 16),
            _MacroLegend(
              label: 'Fat',
              grams: fatGrams,
              color: AppColors.rose,
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedSegment extends StatefulWidget {
  const _AnimatedSegment({
    required this.flex,
    required this.color,
    required this.delay,
  });
  final double flex;
  final Color color;
  final Duration delay;

  @override
  State<_AnimatedSegment> createState() => _AnimatedSegmentState();
}

class _AnimatedSegmentState extends State<_AnimatedSegment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slower,
    );
    _animation = CurvedAnimation(parent: _controller, curve: AppMotion.emphasized);
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (widget.flex * 1000).round().clamp(1, 100000),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(color: widget.color),
          );
        },
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  const _MacroLegend({
    required this.label,
    required this.grams,
    required this.color,
  });
  final String label;
  final double grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  '${grams.toStringAsFixed(0)}g',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}