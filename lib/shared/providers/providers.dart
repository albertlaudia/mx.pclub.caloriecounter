import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/food_search_repository.dart';
import '../data/repositories/meal_repository.dart';
import '../data/sources/local_meal_cache.dart';

/// Meal repository singleton
final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository();
});

/// Food search repository singleton
final foodSearchRepositoryProvider = Provider<FoodSearchRepository>((ref) {
  return FoodSearchRepository();
});

/// Selected date (defaults to today)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// All meals for the selected date
final mealsForDateProvider = Provider((ref) {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(mealRepositoryProvider);
  return repo.getMealsForDate(date);
});

/// Calorie target — fixed for v1 (no auth), hardcoded reasonable default
final calorieTargetProvider = Provider<int>((ref) => 2000);

/// Aggregate stats for today
final dailyStatsProvider = Provider((ref) {
  final meals = ref.watch(mealsForDateProvider);
  final target = ref.watch(calorieTargetProvider);
  final consumed = meals.fold<double>(0, (s, m) => s + m.totalCalories);
  final protein = meals.fold<double>(0, (s, m) => s + m.totalProtein);
  final carbs = meals.fold<double>(0, (s, m) => s + m.totalCarbs);
  final fat = meals.fold<double>(0, (s, m) => s + m.totalFat);
  return DailyStats(
    consumed: consumed,
    target: target.toDouble(),
    protein: protein,
    carbs: carbs,
    fat: fat,
  );
});

class DailyStats {
  DailyStats({
    required this.consumed,
    required this.target,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  final double consumed;
  final double target;
  final double protein;
  final double carbs;
  final double fat;

  double get remaining => (target - consumed).clamp(0, target).toDouble();
  double get progress => (consumed / target).clamp(0.0, 1.0);
  bool get isOverTarget => consumed > target;

  // Macro percentages for the ring
  double get proteinKcal => protein * 4;
  double get carbsKcal => carbs * 4;
  double get fatKcal => fat * 9;
}

/// Cache init — call once at app start
final cacheInitProvider = FutureProvider((ref) async {
  await LocalMealCache.instance.init();
});