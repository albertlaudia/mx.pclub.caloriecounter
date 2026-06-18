import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_item.freezed.dart';
part 'food_item.g.dart';

@freezed
class FoodItem with _$FoodItem {
  const factory FoodItem({
    required String name,
    required double portionGrams,
    required double calories,
    required double caloriesPer100g,
    required double protein,
    required double carbs,
    required double fat,
    required double confidence,
    required String category,
    String? emoji,
    String? visualCues,
  }) = _FoodItem;

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);
}

extension FoodItemX on FoodItem {
  bool get isLowConfidence => confidence < 0.6;

  String get displayName {
    return name
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String get categoryEmoji {
    if (emoji != null) return emoji!;
    switch (category.toLowerCase()) {
      case 'protein':
        return '🍗';
      case 'carb':
        return '🍚';
      case 'vegetable':
        return '🥦';
      case 'fruit':
        return '🍎';
      case 'fat':
        return '🥑';
      case 'dairy':
        return '🧀';
      case 'beverage':
        return '🥤';
      default:
        return '🍽️';
    }
  }
}