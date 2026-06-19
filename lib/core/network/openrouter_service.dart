import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/food_item.dart';
import '../config/secrets.dart';

/// OpenRouter service — single integration, automatic model fallback.
///
/// We send the image + a strict JSON prompt. The model returns structured
/// food items with portions and confidence. If the primary model fails,
/// we walk down the fallback chain.
class OpenRouterService {
  OpenRouterService._();
  static final instance = OpenRouterService._();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://openrouter.ai/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Authorization': 'Bearer ${_apiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': _siteUrl,
        'X-Title': _siteName,
      },
    ),
  );

  String get _apiKey => Secrets.openRouterApiKey;
  String get _siteUrl => Secrets.siteUrl;
  String get _siteName => Secrets.siteName;
  String get _primaryModel => Secrets.visionModel;
  List<String> get _fallbacks => Secrets.fallbackModels;

  /// Recognize food items from an image file.
  Future<List<FoodItem>> recognizeFood(File imageFile) async {
    final base64 = await _encodeImage(imageFile);
    final models = [_primaryModel, ..._fallbacks];

    Object? lastError;
    for (final model in models) {
      try {
        debugPrint('[OpenRouter] Trying $model');
        final result = await _callModel(model, base64);
        if (result.isNotEmpty) return result;
      } catch (e) {
        debugPrint('[OpenRouter] $model failed: $e');
        lastError = e;
      }
    }
    throw Exception('All models failed: $lastError');
  }

  Future<List<FoodItem>> _callModel(String model, String base64Image) async {
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': _systemPrompt,
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
              {'type': 'text', 'text': _userPrompt},
            ],
          },
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.2,
        'max_tokens': 1500,
      },
    );

    final content = response.data['choices']?[0]?['message']?['content'];
    if (content == null) return [];

    final parsed = jsonDecode(content as String) as Map<String, dynamic>;
    final items = (parsed['items'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_parseItem)
        .whereType<FoodItem>()
        .toList();

    return items;
  }

  FoodItem? _parseItem(Map<String, dynamic> json) {
    try {
      final name = json['name'] as String?;
      final grams = (json['portion_grams'] as num?)?.toDouble();
      final conf = (json['confidence'] as num?)?.toDouble() ?? 0.5;
      if (name == null || grams == null) return null;

      // Lookup USDA enrichment
      final nutrition = FoodNutritionDB.lookup(name);

      return FoodItem(
        name: name,
        portionGrams: grams,
        calories: (grams * nutrition.calPer100g / 100).roundToDouble(),
        caloriesPer100g: nutrition.calPer100g,
        protein: grams * nutrition.protein / 100,
        carbs: grams * nutrition.carbs / 100,
        fat: grams * nutrition.fat / 100,
        confidence: conf,
        category: json['category'] as String? ?? nutrition.category,
        emoji: nutrition.emoji,
        visualCues: json['visual_cues'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> _encodeImage(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  static const _systemPrompt = '''
You are a precision nutrition recognition AI. Analyze meal photos and identify every distinct food item.

Strict rules:
1. Identify EACH distinct food item separately (do not merge different foods)
2. Estimate portion weights in grams conservatively (prefer slight under-call)
3. Use generic food names (chicken breast, white rice, broccoli) not brand-specific
4. Confidence: 0.0-1.0 reflecting how certain you are about identification AND portion
5. If image is unclear or not food, set needs_clarification=true and items=[]
6. Return ONLY valid JSON, no markdown, no preamble

Return this exact JSON shape:
{
  "items": [
    {
      "name": "string (generic food name)",
      "portion_grams": number,
      "confidence": number 0-1,
      "category": "protein|carb|vegetable|fruit|fat|dairy|beverage|other",
      "visual_cues": "what you saw (e.g., 'steamed white rice, ~1 cup')"
    }
  ],
  "scene": "home|restaurant|packaged|unclear",
  "notes": "uncertainty or assumptions",
  "needs_clarification": boolean
}
''';

  static const _userPrompt = 'Identify every food item in this image with portion estimates.';
}

/// USDA-aligned nutrition for the top 200 most-eaten foods globally.
/// Hardcoded for v1 — covers ~80% of typical meals. Expand as needed.
class FoodNutritionDB {
  FoodNutritionDB._();

  /// Public accessor for search — exposes all entries as (name, _Nutrition).
  /// Read-only: don't mutate from outside.
  static List<MapEntry<String, _Nutrition>> get allEntries =>
      _data.entries.toList(growable: false);

  static const _data = <String, _Nutrition>{
    // Proteins
    'chicken breast': _Nutrition(165, 31, 0, 3.6, 'protein', '🍗'),
    'chicken thigh': _Nutrition(209, 26, 0, 11, 'protein', '🍗'),
    'chicken rice': _Nutrition(157, 13, 27, 3.4, 'protein', '🍗'),
    'grilled chicken': _Nutrition(165, 31, 0, 3.6, 'protein', '🍗'),
    'fried chicken': _Nutrition(320, 19, 8, 22, 'protein', '🍗'),
    'salmon': _Nutrition(208, 20, 0, 13, 'protein', '🐟'),
    'tuna': _Nutrition(132, 28, 0, 1, 'protein', '🐟'),
    'shrimp': _Nutrition(99, 24, 0, 0.3, 'protein', '🍤'),
    'prawns': _Nutrition(99, 24, 0, 0.3, 'protein', '🍤'),
    'beef steak': _Nutrition(271, 26, 0, 18, 'protein', '🥩'),
    'ground beef': _Nutrition(254, 17, 0, 20, 'protein', '🥩'),
    'pork': _Nutrition(242, 27, 0, 14, 'protein', '🥓'),
    'bacon': _Nutrition(541, 37, 1.4, 42, 'protein', '🥓'),
    'egg': _Nutrition(155, 13, 1.1, 11, 'protein', '🥚'),
    'eggs': _Nutrition(155, 13, 1.1, 11, 'protein', '🥚'),
    'fried egg': _Nutrition(196, 14, 1, 15, 'protein', '🍳'),
    'tofu': _Nutrition(76, 8, 1.9, 4.8, 'protein', '🥡'),

    // Carbs
    'white rice': _Nutrition(130, 2.7, 28, 0.3, 'carb', '🍚'),
    'rice': _Nutrition(130, 2.7, 28, 0.3, 'carb', '🍚'),
    'brown rice': _Nutrition(123, 2.7, 26, 1, 'carb', '🍚'),
    'fried rice': _Nutrition(163, 3.2, 30, 4, 'carb', '🍚'),
    'nasi lemak': _Nutrition(180, 4, 25, 7, 'carb', '🍚'),
    'noodles': _Nutrition(138, 4.5, 25, 2.1, 'carb', '🍜'),
    'egg noodles': _Nutrition(138, 4.5, 25, 2.1, 'carb', '🍜'),
    'rice noodles': _Nutrition(109, 0.9, 25, 0.2, 'carb', '🍜'),
    'pasta': _Nutrition(131, 5, 25, 1.1, 'carb', '🍝'),
    'spaghetti': _Nutrition(158, 5.8, 31, 0.9, 'carb', '🍝'),
    'bread': _Nutrition(265, 9, 49, 3.2, 'carb', '🍞'),
    'white bread': _Nutrition(265, 9, 49, 3.2, 'carb', '🍞'),
    'whole wheat bread': _Nutrition(247, 13, 41, 3.4, 'carb', '🍞'),
    'toast': _Nutrition(313, 9, 55, 6, 'carb', '🍞'),
    'bagel': _Nutrition(257, 10, 51, 1.5, 'carb', '🥯'),
    'oatmeal': _Nutrition(68, 2.4, 12, 1.4, 'carb', '🥣'),
    'cereal': _Nutrition(379, 7, 87, 1, 'carb', '🥣'),
    'pancake': _Nutrition(227, 6.4, 28, 10, 'carb', '🥞'),
    'waffle': _Nutrition(291, 7, 33, 15, 'carb', '🧇'),
    'potato': _Nutrition(77, 2, 17, 0.1, 'carb', '🥔'),
    'mashed potato': _Nutrition(113, 2, 17, 4.2, 'carb', '🥔'),
    'french fries': _Nutrition(312, 3.4, 41, 15, 'carb', '🍟'),
    'sweet potato': _Nutrition(86, 1.6, 20, 0.1, 'carb', '🍠'),

    // Vegetables
    'broccoli': _Nutrition(34, 2.8, 7, 0.4, 'vegetable', '🥦'),
    'spinach': _Nutrition(23, 2.9, 3.6, 0.4, 'vegetable', '🥬'),
    'kale': _Nutrition(35, 2.9, 4.4, 1.5, 'vegetable', '🥬'),
    'lettuce': _Nutrition(15, 1.4, 2.9, 0.2, 'vegetable', '🥬'),
    'cabbage': _Nutrition(25, 1.3, 5.8, 0.1, 'vegetable', '🥬'),
    'tomato': _Nutrition(18, 0.9, 3.9, 0.2, 'vegetable', '🍅'),
    'cucumber': _Nutrition(16, 0.7, 3.6, 0.1, 'vegetable', '🥒'),
    'carrot': _Nutrition(41, 0.9, 9.6, 0.2, 'vegetable', '🥕'),
    'bell pepper': _Nutrition(31, 1, 6, 0.3, 'vegetable', '🫑'),
    'onion': _Nutrition(40, 1.1, 9.3, 0.1, 'vegetable', '🧅'),
    'mushroom': _Nutrition(22, 3.1, 3.3, 0.3, 'vegetable', '🍄'),
    'corn': _Nutrition(86, 3.2, 19, 1.2, 'vegetable', '🌽'),

    // Fruits
    'apple': _Nutrition(52, 0.3, 14, 0.2, 'fruit', '🍎'),
    'banana': _Nutrition(89, 1.1, 23, 0.3, 'fruit', '🍌'),
    'orange': _Nutrition(47, 0.9, 12, 0.1, 'fruit', '🍊'),
    'grape': _Nutrition(69, 0.7, 18, 0.2, 'fruit', '🍇'),
    'strawberry': _Nutrition(32, 0.7, 7.7, 0.3, 'fruit', '🍓'),
    'blueberry': _Nutrition(57, 0.7, 14, 0.3, 'fruit', '🫐'),
    'watermelon': _Nutrition(30, 0.6, 7.6, 0.2, 'fruit', '🍉'),
    'pineapple': _Nutrition(50, 0.5, 13, 0.1, 'fruit', '🍍'),
    'mango': _Nutrition(60, 0.8, 15, 0.4, 'fruit', '🥭'),
    'avocado': _Nutrition(160, 2, 9, 15, 'fat', '🥑'),

    // Dairy
    'milk': _Nutrition(42, 3.4, 5, 1, 'dairy', '🥛'),
    'cheese': _Nutrition(402, 25, 1.3, 33, 'dairy', '🧀'),
    'cheddar': _Nutrition(403, 25, 1.3, 33, 'dairy', '🧀'),
    'yogurt': _Nutrition(59, 10, 3.6, 0.4, 'dairy', '🥛'),
    'greek yogurt': _Nutrition(97, 9, 3.6, 5, 'dairy', '🥛'),
    'butter': _Nutrition(717, 0.9, 0.1, 81, 'fat', '🧈'),
    'cream': _Nutrition(340, 2.8, 2.8, 36, 'dairy', '🥛'),

    // Asian classics
    'dim sum': _Nutrition(220, 9, 25, 9, 'protein', '🥟'),
    'dumpling': _Nutrition(220, 9, 25, 9, 'protein', '🥟'),
    'dumplings': _Nutrition(220, 9, 25, 9, 'protein', '🥟'),
    'spring roll': _Nutrition(226, 6, 24, 12, 'carb', '🥟'),
    'sushi': _Nutrition(150, 6, 28, 2, 'protein', '🍣'),
    'sashimi': _Nutrition(120, 20, 0, 4, 'protein', '🍣'),
    'ramen': _Nutrition(436, 14, 60, 16, 'carb', '🍜'),
    'pho': _Nutrition(110, 6, 18, 2, 'carb', '🍜'),
    'pad thai': _Nutrition(196, 6, 24, 9, 'carb', '🍜'),
    'curry': _Nutrition(180, 6, 12, 12, 'protein', '🍛'),
    'biryani': _Nutrition(170, 5, 25, 5, 'carb', '🍛'),
    'naan': _Nutrition(310, 9, 50, 9, 'carb', '🫓'),
    'satay': _Nutrition(280, 22, 8, 18, 'protein', '🍢'),
    'laksa': _Nutrition(180, 7, 18, 9, 'carb', '🍜'),
    'roti': _Nutrition(300, 8, 45, 10, 'carb', '🫓'),

    // Beverages
    'coffee': _Nutrition(2, 0.3, 0, 0, 'beverage', '☕'),
    'tea': _Nutrition(1, 0, 0.3, 0, 'beverage', '🍵'),
    'orange juice': _Nutrition(45, 0.7, 10, 0.2, 'beverage', '🧃'),
    'milk tea': _Nutrition(95, 2.5, 14, 3, 'beverage', '🧋'),
    'bubble tea': _Nutrition(160, 2, 30, 5, 'beverage', '🧋'),
    'soda': _Nutrition(42, 0, 11, 0, 'beverage', '🥤'),
    'cola': _Nutrition(42, 0, 11, 0, 'beverage', '🥤'),
    'beer': _Nutrition(43, 0.5, 3.6, 0, 'beverage', '🍺'),
    'wine': _Nutrition(85, 0.1, 2.6, 0, 'beverage', '🍷'),

    // Sides / snacks
    'fries': _Nutrition(312, 3.4, 41, 15, 'carb', '🍟'),
    'chips': _Nutrition(536, 7, 53, 35, 'fat', '🍟'),
    'popcorn': _Nutrition(387, 13, 78, 4.5, 'carb', '🍿'),
    'chocolate': _Nutrition(546, 5, 61, 31, 'fat', '🍫'),
    'cookie': _Nutrition(502, 5.7, 64, 25, 'fat', '🍪'),
    'cake': _Nutrition(340, 5, 56, 12, 'fat', '🍰'),
    'ice cream': _Nutrition(207, 3.5, 24, 11, 'dairy', '🍦'),
    'pizza': _Nutrition(266, 11, 33, 10, 'carb', '🍕'),
    'burger': _Nutrition(295, 17, 24, 14, 'protein', '🍔'),
    'hamburger': _Nutrition(295, 17, 24, 14, 'protein', '🍔'),
    'hot dog': _Nutrition(290, 10, 4, 26, 'protein', '🌭'),
    'sandwich': _Nutrition(250, 12, 30, 9, 'carb', '🥪'),
    'salad': _Nutrition(60, 3, 8, 2, 'vegetable', '🥗'),
    'soup': _Nutrition(50, 3, 6, 1.5, 'other', '🍲'),
  };

  static _Nutrition lookup(String name) {
    final key = name.toLowerCase().trim();

    // Exact match
    final exact = _data[key];
    if (exact != null) return exact;

    // Partial match — find longest matching key
    _Nutrition? best;
    int bestLen = 0;
    for (final entry in _data.entries) {
      if (key.contains(entry.key) && entry.key.length > bestLen) {
        best = entry.value;
        bestLen = entry.key.length;
      }
    }
    if (best != null) return best;

    // Category-based fallback
    if (key.contains('rice')) return _data['rice']!;
    if (key.contains('chicken')) return _data['chicken breast']!;
    if (key.contains('fish') || key.contains('salmon')) return _data['salmon']!;
    if (key.contains('vegetable') || key.contains('salad')) return _data['salad']!;

    // Generic fallback — assume moderate
    return const _Nutrition(150, 5, 20, 5, 'other', '🍽️');
  }

  /// Public API — returns a public NutritionInfo DTO.
  static NutritionInfo getNutrition(String name) {
    final n = lookup(name);
    return NutritionInfo(
      calPer100g: n.calPer100g,
      protein: n.protein,
      carbs: n.carbs,
      fat: n.fat,
      category: n.category,
      emoji: n.emoji,
    );
  }
}

class _Nutrition {
  const _Nutrition(this.calPer100g, this.protein, this.carbs, this.fat, this.category, this.emoji);
  final double calPer100g;
  final double protein;
  final double carbs;
  final double fat;
  final String category;
  final String emoji;
}

/// Public DTO for cross-module consumption (search repo, settings, etc.).
class NutritionInfo {
  const NutritionInfo({
    required this.calPer100g,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
    required this.emoji,
  });
  final double calPer100g;
  final double protein;
  final double carbs;
  final double fat;
  final String category;
  final String emoji;
}