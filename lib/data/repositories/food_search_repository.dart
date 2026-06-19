import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/openrouter_service.dart';
import '../models/food_item.dart';

/// Food search — local DB + Open Food Facts barcode lookup.
///
/// Open Food Facts is a free, open database of 4M+ packaged products worldwide.
/// Barcode scan → instant nutrition lookup. No API key needed.
class FoodSearchRepository {
  FoodSearchRepository({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  static const _openFoodFactsBase = 'https://world.openfoodfacts.org';

  /// Search local nutrition DB by query (instant, offline).
  List<FoodItem> searchLocal(String query, {int limit = 30}) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    final results = <_ScoredFoodItem>[];

    for (final entry in FoodNutritionDB.allEntries) {
      final score = _score(entry.key, q);
      if (score > 0) {
        results.add(_ScoredFoodItem(entry, score));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results
        .take(limit)
        .map((s) => _buildFoodItem(s.entry.key, 100))
        .toList();
  }

  /// Lookup barcode via Open Food Facts (online).
  Future<FoodItem?> lookupBarcode(String barcode) async {
    try {
      final res = await _dio.get(
        '$_openFoodFactsBase/api/v2/product/$barcode.json',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          headers: {'User-Agent': 'CalorieApp/1.0 (Flutter)'},
        ),
      );

      if (res.statusCode != 200) return null;
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['status'] != 1) return null;

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final name = product['product_name'] as String? ??
          product['generic_name'] as String? ??
          'Unknown product';
      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

      final cal100 = (nutriments['energy-kcal_100g'] as num?)?.toDouble() ??
          ((nutriments['energy_100g'] as num?)?.toDouble() ?? 0) / 4.184;
      final protein = (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0;
      final carbs = (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0;
      final fat = (nutriments['fat_100g'] as num?)?.toDouble() ?? 0;
      final brand = product['brands'] as String?;

      return FoodItem(
        name: brand != null && brand.isNotEmpty ? '$brand · $name' : name,
        portionGrams: 100,
        calories: cal100,
        caloriesPer100g: cal100,
        protein: protein,
        carbs: carbs,
        fat: fat,
        confidence: 1.0,
        category: 'packaged',
        emoji: '📦',
        visualCues: 'Barcode $barcode',
      );
    } catch (e) {
      debugPrint('[OFF] Barcode lookup failed: $e');
      return null;
    }
  }

  /// Full-text search of Open Food Facts (online).
  Future<List<FoodItem>> searchOnline(String query, {int limit = 20}) async {
    try {
      final res = await _dio.get(
        '$_openFoodFactsBase/cgi/search.pl',
        queryParameters: {
          'search_terms': query,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': limit,
          'fields': 'product_name,brands,nutriments',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          headers: {'User-Agent': 'CalorieApp/1.0 (Flutter)'},
        ),
      );

      if (res.statusCode != 200) return [];
      final products = (res.data['products'] as List? ?? []);
      return products
          .cast<Map<String, dynamic>>()
          .map((p) => _parseOffProduct(p))
          .whereType<FoodItem>()
          .toList();
    } catch (e) {
      debugPrint('[OFF] Online search failed: $e');
      return [];
    }
  }

  FoodItem? _parseOffProduct(Map<String, dynamic> p) {
    final name = p['product_name'] as String?;
    if (name == null || name.isEmpty) return null;
    final brand = p['brands'] as String?;
    final n = p['nutriments'] as Map<String, dynamic>? ?? {};
    final cal100 = (n['energy-kcal_100g'] as num?)?.toDouble() ?? 0;
    if (cal100 == 0) return null;

    return FoodItem(
      name: brand != null && brand.isNotEmpty ? '$brand · $name' : name,
      portionGrams: 100,
      calories: cal100,
      caloriesPer100g: cal100,
      protein: (n['proteins_100g'] as num?)?.toDouble() ?? 0,
      carbs: (n['carbohydrates_100g'] as num?)?.toDouble() ?? 0,
      fat: (n['fat_100g'] as num?)?.toDouble() ?? 0,
      confidence: 1.0,
      category: 'packaged',
      emoji: '📦',
    );
  }

  FoodItem _buildFoodItem(String key, double grams) {
    final n = FoodNutritionDB.getNutrition(key);
    return FoodItem(
      name: key,
      portionGrams: grams,
      calories: (grams * n.calPer100g / 100).roundToDouble(),
      caloriesPer100g: n.calPer100g,
      protein: grams * n.protein / 100,
      carbs: grams * n.carbs / 100,
      fat: grams * n.fat / 100,
      confidence: 1.0,
      category: n.category,
      emoji: n.emoji,
    );
  }

  /// Score an entry against a query — supports partial matches and word starts.
  int _score(String key, String query) {
    if (key == query) return 100;
    if (key.startsWith(query)) return 80;
    if (key.contains(query)) return 60;
    // Word-start match
    final keyWords = key.split(' ');
    final queryWords = query.split(' ');
    int score = 0;
    for (final qw in queryWords) {
      for (final kw in keyWords) {
        if (kw.startsWith(qw)) score += 20;
        if (kw.contains(qw)) score += 10;
      }
    }
    return score;
  }
}

class _ScoredFoodItem {
  _ScoredFoodItem(this.entry, this.score);
  final MapEntry<String, dynamic> entry;
  final int score;
}