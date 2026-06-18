import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_item.dart';
import '../models/meal.dart';

/// Local meal cache — Hive box for offline-first storage.
///
/// Two purposes:
/// 1. Offline queue for unsynced meals (no auth, but we keep meals on-device)
/// 2. Image hash → items lookup for instant repeat meals
class LocalMealCache {
  LocalMealCache._();
  static final instance = LocalMealCache._();

  static const _mealsBox = 'meals';
  static const _imageHashBox = 'image_hashes';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_mealsBox);
    await Hive.openBox<String>(_imageHashBox);
  }

  // ── Meals ────────────────────────────────────────────────────
  Future<void> saveMeal(Meal meal) async {
    final box = Hive.box<String>(_mealsBox);
    await box.put(meal.id, jsonEncode(meal.toJson()));
  }

  Future<void> deleteMeal(String id) async {
    await Hive.box<String>(_mealsBox).delete(id);
  }

  List<Meal> getAllMeals() {
    final box = Hive.box<String>(_mealsBox);
    return box.values
        .map((raw) {
          try {
            return Meal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Meal>()
        .toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  List<Meal> getMealsForDate(DateTime date) {
    return getAllMeals().where((m) {
      return m.loggedAt.year == date.year &&
          m.loggedAt.month == date.month &&
          m.loggedAt.day == date.day;
    }).toList();
  }

  // ── Repeat meals ─────────────────────────────────────────────
  /// Returns the most recent identical meal (by food name signature),
  /// enabling 1-tap re-log without re-snapping or hitting the API.
  Meal? findRepeatMeal(List<FoodItem> items) {
    if (items.isEmpty) return null;
    final signature = _itemSignature(items);
    final all = getAllMeals();

    Meal? best;
    int bestScore = 0;
    for (final meal in all) {
      final score = _similarity(signature, _itemSignature(meal.items));
      if (score > bestScore && score >= 70) {
        best = meal;
        bestScore = score;
      }
    }
    return best;
  }

  String _itemSignature(List<FoodItem> items) {
    final sorted = [...items]..sort((a, b) => a.name.compareTo(b.name));
    return sorted.map((i) => '${i.name.toLowerCase()}_${i.portionGrams.round()}').join('|');
  }

  int _similarity(String a, String b) {
    if (a == b) return 100;
    final aSet = a.split('|').toSet();
    final bSet = b.split('|').toSet();
    final inter = aSet.intersection(bSet).length;
    final union = aSet.union(bSet).length;
    return ((inter / union) * 100).round();
  }

  // ── Image hash cache ─────────────────────────────────────────
  /// Cache image hash → recognized items to skip the API on identical photos.
  Future<void> cacheImageHash(String imagePath, List<FoodItem> items) async {
    final hash = await computeImageHash(imagePath);
    final box = Hive.box<String>(_imageHashBox);
    await box.put(
      hash,
      jsonEncode(items.map((i) => i.toJson()).toList()),
    );
  }

  List<FoodItem>? lookupImageHash(String imagePath) {
    final hash = _quickImageHash(imagePath);
    final raw = Hive.box<String>(_imageHashBox).get(hash);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map((j) => FoodItem.fromJson(j))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Quick perceptual-ish hash for fast lookup (file size + first 4KB hash).
  /// Not cryptographic — just a fast cache key.
  String _quickImageHash(String path) {
    final file = File(path);
    final stat = file.statSync();
    final bytes = file.readAsBytesSync().take(4096).toList();
    final digest = md5.convert([stat.size, ...bytes]);
    return digest.toString();
  }

  Future<String> computeImageHash(String path) async => _quickImageHash(path);
}