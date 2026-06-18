import 'package:freezed_annotation/freezed_annotation.dart';
import 'meal.dart';

part 'daily_log.freezed.dart';
part 'daily_log.g.dart';

@freezed
class DailyLog with _$DailyLog {
  const factory DailyLog({
    required DateTime date,
    required List<Meal> meals,
    required int calorieTarget,
  }) = _DailyLog;

  factory DailyLog.fromJson(Map<String, dynamic> json) =>
      _$DailyLogFromJson(json);
}

extension DailyLogX on DailyLog {
  double get consumedCalories =>
      meals.fold(0.0, (sum, meal) => sum + meal.totalCalories);

  double get remainingCalories =>
      (calorieTarget - consumedCalories).clamp(0, calorieTarget).toDouble();

  double get progress => consumedCalories / calorieTarget;

  double get consumedProtein =>
      meals.fold(0.0, (s, m) => s + m.totalProtein);
  double get consumedCarbs =>
      meals.fold(0.0, (s, m) => s + m.totalCarbs);
  double get consumedFat => meals.fold(0.0, (s, m) => s + m.totalFat);

  bool get isOverTarget => consumedCalories > calorieTarget;
}