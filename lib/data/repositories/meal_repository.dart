import 'dart:io';
import '../../core/network/openrouter_service.dart';
import '../models/meal.dart';
import '../sources/local_meal_cache.dart';

/// Meal repository — orchestrates local cache + remote vision.
///
/// Flow for a new meal:
///   1. Quick image-hash lookup (instant for repeat photos)
///   2. If miss: call OpenRouter → M3
///   3. Save items, cache hash for next time
///   4. Find repeat meal suggestion (same items, recent)
///   5. Return to UI
class MealRepository {
  MealRepository({
    OpenRouterService? visionService,
    LocalMealCache? cache,
  })  : _vision = visionService ?? OpenRouterService.instance,
        _cache = cache ?? LocalMealCache.instance;

  final OpenRouterService _vision;
  final LocalMealCache _cache;

  Future<RecognitionResult> recognizeMeal({
    required File imageFile,
    required MealType type,
  }) async {
    // Step 1: image-hash cache lookup
    final cached = _cache.lookupImageHash(imageFile.path);
    if (cached != null && cached.isNotEmpty) {
      final meal = Meal(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        loggedAt: DateTime.now(),
        type: type,
        items: cached,
        imagePath: imageFile.path,
        fromCache: true,
      );
      await _cache.saveMeal(meal);
      return RecognitionResult(meal: meal, fromImageCache: true);
    }

    // Step 2: call OpenRouter → M3
    final items = await _vision.recognizeFood(imageFile);

    if (items.isEmpty) {
      throw const RecognitionFailedException(
        "Couldn't recognize this meal. Try a clearer photo or add manually.",
      );
    }

    // Step 3: save image hash for instant re-log next time
    await _cache.cacheImageHash(imageFile.path, items);

    // Step 4: build meal
    final meal = Meal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      loggedAt: DateTime.now(),
      type: type,
      items: items,
      imagePath: imageFile.path,
    );
    await _cache.saveMeal(meal);

    // Step 5: find repeat suggestion
    final repeat = _cache.findRepeatMeal(items);

    return RecognitionResult(meal: meal, repeatSuggestion: repeat);
  }

  Future<Meal> logRepeatMeal(Meal previous) async {
    final meal = previous.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      loggedAt: DateTime.now(),
      fromCache: true,
    );
    await _cache.saveMeal(meal);
    return meal;
  }

  Future<void> updateMeal(Meal meal) async {
    await _cache.saveMeal(meal);
  }

  Future<void> deleteMeal(String id) async {
    await _cache.deleteMeal(id);
  }

  List<Meal> getMealsForDate(DateTime date) =>
      _cache.getMealsForDate(date);

  List<Meal> getAllMeals() => _cache.getAllMeals();
}

class RecognitionResult {
  RecognitionResult({
    required this.meal,
    this.fromImageCache = false,
    this.repeatSuggestion,
  });
  final Meal meal;
  final bool fromImageCache;
  final Meal? repeatSuggestion;
}

class RecognitionFailedException implements Exception {
  const RecognitionFailedException(this.message);
  final String message;
  @override
  String toString() => message;
}