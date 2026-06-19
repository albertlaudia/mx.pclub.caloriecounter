import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/animation/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/food_item.dart';
import '../../data/models/meal.dart';
import '../../shared/providers/providers.dart';

/// Portion editor — set grams, choose meal type, save.
class PortionEditorScreen extends ConsumerStatefulWidget {
  const PortionEditorScreen({super.key, required this.item});
  final FoodItem item;

  @override
  ConsumerState<PortionEditorScreen> createState() => _PortionEditorScreenState();
}

class _PortionEditorScreenState extends ConsumerState<PortionEditorScreen> {
  late double _grams;
  late MealType _mealType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _grams = widget.item.portionGrams;
    _mealType = _inferMealType();
  }

  MealType _inferMealType() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 15) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }

  double get _totalCal => _grams * widget.item.caloriesPer100g / 100;

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final repo = ref.read(mealRepositoryProvider);
    final adjustedItem = widget.item.copyWith(
      portionGrams: _grams,
      calories: _totalCal,
    );
    final meal = Meal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      loggedAt: DateTime.now(),
      type: _mealType,
      items: [adjustedItem],
    );
    await repo.updateMeal(meal);
    HapticFeedback.heavyImpact();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add to meal'),
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        widget.item.categoryEmoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.item.caloriesPer100g.round()} kcal per 100g',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Meal type selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MEAL TYPE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: MealType.values.map((type) {
                    final selected = type == _mealType;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _mealType = type),
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.brand : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? AppColors.brand : AppColors.divider,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  type.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type.label,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: selected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Portion slider
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PORTION',
                      style: theme.textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      '${_grams.round()}g',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.brand,
                    inactiveTrackColor: AppColors.brandSoft,
                    thumbColor: AppColors.brand,
                    overlayColor: AppColors.brand.withOpacity(0.2),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    min: 10,
                    max: 500,
                    divisions: 49,
                    value: _grams.clamp(10, 500),
                    onChanged: (v) => setState(() => _grams = v),
                  ),
                ),
                // Quick presets
                Wrap(
                  spacing: 8,
                  children: [50, 100, 150, 200, 300].map((g) {
                    return ChoiceChip(
                      label: Text('${g}g'),
                      selected: (_grams - g).abs() < 1,
                      onSelected: (_) => setState(() => _grams = g.toDouble()),
                      selectedColor: AppColors.brandSoft,
                      labelStyle: TextStyle(
                        color: (_grams - g).abs() < 1
                            ? AppColors.brand
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: (_grams - g).abs() < 1
                            ? AppColors.brand
                            : AppColors.divider,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom summary + save
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
                      '${_totalCal.round()} kcal',
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
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Log meal'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}