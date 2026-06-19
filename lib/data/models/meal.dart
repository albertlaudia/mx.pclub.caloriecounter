import 'package:freezed_annotation/freezed_annotation.dart';
import 'food_item.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍿';
    }
  }
}

@freezed
class Meal with _$Meal {
  const Meal._(); // enable computed getters

  const factory Meal({
    required String id,
    required DateTime loggedAt,
    required MealType type,
    required List<FoodItem> items,
    String? imagePath,
    String? notes,
    @Default(false) bool fromCache,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);

  // Computed getters — defined directly on the union class so they're always visible
  double get totalCalories =>
      items.fold(0.0, (sum, item) => sum + item.calories);

  double get totalProtein => items.fold(0.0, (s, i) => s + i.protein);
  double get totalCarbs => items.fold(0.0, (s, i) => s + i.carbs);
  double get totalFat => items.fold(0.0, (s, i) => s + i.fat);

  String get displayTitle {
    if (items.isEmpty) return 'Empty meal';
    if (items.length == 1) return items.first.displayName;
    return '${items.first.displayName} +${items.length - 1}';
  }
}
