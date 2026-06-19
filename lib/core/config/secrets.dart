/// CI/Development secrets — safe defaults for local/CI builds.
/// Replace with real values in production or via environment variables.
class Secrets {
  Secrets._();
  static const String openRouterApiKey = '';
  static const String siteUrl = 'https://calorieapp.app';
  static const String siteName = 'CalorieApp';
  static const String visionModel = 'minimax/minimax-m3';
  static const String _fallbacksRaw = 'google/gemini-2.5-flash,openai/gpt-4o-mini';

  static List<String> get fallbackModels =>
      _fallbacksRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}
