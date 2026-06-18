import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animation/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/food_item.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/meal_repository.dart';
import '../../shared/providers/providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.imagePath});
  final String imagePath;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen>
    with TickerProviderStateMixin {
  late Future<RecognitionResult> _future;
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _future = _recognize();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  Future<RecognitionResult> _recognize() async {
    final repo = ref.read(mealRepositoryProvider);
    return repo.recognizeMeal(
      imageFile: File(widget.imagePath),
      type: _inferMealType(),
    );
  }

  MealType _inferMealType() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 15) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Review'),
        actions: [
          TextButton(
            onPressed: () {
              // Re-scan
              setState(() {
                _future = _recognize();
              });
            },
            child: const Text('Re-scan'),
          ),
        ],
      ),
      body: FutureBuilder<RecognitionResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _AnalyzingState(imagePath: widget.imagePath);
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() => _future = _recognize()),
            );
          }
          final result = snapshot.data!;
          return _EditableResult(
            result: result,
            onSaved: () {
              _successController.forward(from: 0);
              HapticFeedback.heavyImpact();
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) context.go('/');
              });
            },
          );
        },
      ),
    );
  }
}

// ─── States ────────────────────────────────────────────────────────

class _AnalyzingState extends StatelessWidget {
  const _AnalyzingState({required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: FileImage(File(imagePath)),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _AnalyzingPulse(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Analyzing your meal…',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Identifying food items and estimating portions',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _AnalyzingPulse extends StatefulWidget {
  const _AnalyzingPulse();

  @override
  State<_AnalyzingPulse> createState() => _AnalyzingPulseState();
}

class _AnalyzingPulseState extends State<_AnalyzingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(1.0 - t),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_menu, size: 36, color: AppColors.brand),
          ),
          const SizedBox(height: 24),
          Text(
            "Couldn't read this photo",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a clearer shot with better lighting, or log manually.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}

class _EditableResult extends ConsumerStatefulWidget {
  const _EditableResult({required this.result, required this.onSaved});
  final RecognitionResult result;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditableResult> createState() => _EditableResultState();
}

class _EditableResultState extends ConsumerState<_EditableResult> {
  late List<FoodItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.result.meal.items];
  }

  void _updatePortion(int index, double grams) {
    setState(() {
      final old = _items[index];
      _items[index] = old.copyWith(
        portionGrams: grams,
        calories: (grams * old.caloriesPer100g / 100).roundToDouble(),
      );
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _save() async {
    final repo = ref.read(mealRepositoryProvider);
    final updatedMeal = widget.result.meal.copyWith(items: _items);
    await repo.updateMeal(updatedMeal);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCal = _items.fold<double>(0, (s, i) => s + i.calories);

    return Column(
      children: [
        // Image preview
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: FileImage(File(widget.result.meal.imagePath!)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // From-cache badge
        if (widget.result.fromImageCache)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.mintSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.mint, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Instant match from cache',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Items header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('Identified items', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(
                '${_items.length}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Items list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              return _FoodItemCard(
                item: _items[i],
                onPortionChanged: (g) => _updatePortion(i, g),
                onRemove: () => _removeItem(i),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 100 * i),
                    duration: AppMotion.normal,
                  ).slideY(begin: 0.1, end: 0);
            },
          ),
        ),

        // Bottom save bar
        Container(
          padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: theme.textTheme.bodySmall),
                  Text(
                    '${totalCal.round()} kcal',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                child: FilledButton(
                  onPressed: _items.isEmpty ? null : _save,
                  child: const Text('Log meal'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  const _FoodItemCard({
    required this.item,
    required this.onPortionChanged,
    required this.onRemove,
  });
  final FoodItem item;
  final ValueChanged<double> onPortionChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isLowConfidence
              ? AppColors.amber.withOpacity(0.6)
              : AppColors.divider,
          width: item.isLowConfidence ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(item.categoryEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.displayName,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isLowConfidence)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6E5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'verify',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.calories.round()} kcal · ${item.protein.toStringAsFixed(0)}g P',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textTertiary,
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Portion',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              _PortionStepper(
                grams: item.portionGrams,
                onChanged: onPortionChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortionStepper extends StatelessWidget {
  const _PortionStepper({required this.grams, required this.onChanged});
  final double grams;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _StepBtn(icon: Icons.remove, onTap: () => onChanged((grams - 10).clamp(10, 1000))),
          SizedBox(
            width: 56,
            child: Center(
              child: Text(
                '${grams.round()}g',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: () => onChanged((grams + 10).clamp(10, 1000))),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}