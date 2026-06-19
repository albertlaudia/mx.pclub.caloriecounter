#!/bin/bash
# First-time setup — run once after cloning.
#
# Usage: bash scripts/setup.sh

set -e

echo "🥗 CalorieApp setup"
echo "===================="

# 1. Check Flutter
if ! command -v flutter >/dev/null 2>&1; then
  echo "❌ Flutter not found. Install from https://docs.flutter.dev/get-started/install"
  exit 1
fi

echo "✅ Flutter $(flutter --version | head -1)"

# 2. Install deps
echo ""
echo "📦 Installing dependencies..."
flutter pub get

# 3. Set up secrets
if [ ! -f lib/core/config/secrets.dart ]; then
  echo ""
  echo "🔑 Setting up secrets..."
  cp lib/core/config/secrets.dart.template lib/core/config/secrets.dart
  echo "   Created lib/core/config/secrets.dart"
  echo "   ⚠️  Edit it with your OpenRouter API key from https://openrouter.ai/keys"
else
  echo ""
  echo "🔑 secrets.dart already exists, skipping"
fi

# 4. Generate freezed + hive adapters
echo ""
echo "🔨 Generating code (freezed, json_serializable, hive)..."
dart run build_runner build --delete-conflicting-outputs

# 5. Verify
echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Edit lib/core/config/secrets.dart with your OpenRouter key"
echo "  2. flutter run          # Run on connected device/simulator"
echo "  3. flutter build apk    # Build release APK"
echo "  4. flutter build ios    # Build iOS (macOS only)"