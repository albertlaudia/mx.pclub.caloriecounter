# CalorieApp

AI-powered calorie tracker — **snap, confirm, done.**

The calorie tracker that gets out of your way. Open the app, snap your meal, confirm the AI's guesses, and you're logged. Smart caching makes repeat meals instant (zero taps after the first time).

## Stack

- **Flutter** (iOS + Android, single codebase)
- **Riverpod** — state management
- **GoRouter** — declarative routing with custom transitions
- **Hive** — local cache (offline-first, repeat-meal magic)
- **OpenRouter** → **MiniMax M3** — multimodal vision API
- **Gemini 2.5 Flash** / **GPT-4o-mini** — automatic fallbacks
- **freezed** / **json_serializable** — type-safe models

## Features

- 📸 **Camera-first** — snap a meal, AI identifies items + portions in ~2s
- 🧠 **Multi-item detection** — rice + chicken + greens recognized separately
- ⚡ **Instant repeat meals** — same breakfast tomorrow = 1 tap, no re-snap
- 🔒 **Offline-first** — works without internet; queues meals locally
- 🎨 **Beautiful animations** — custom motion system, buttery 60fps transitions
- 🍱 **Asian food optimized** — top 200 foods hardcoded (rice, noodles, dim sum, etc.)

## Quick start

```bash
# 1. Install Flutter
# https://docs.flutter.dev/get-started/install

# 2. Clone and install
flutter pub get

# 3. Add your OpenRouter key
cp lib/core/config/secrets.dart.template lib/core/config/secrets.dart
# Edit secrets.dart with your OpenRouter API key
# Get one at https://openrouter.ai/keys

# 4. Generate Hive adapters and freezed models
dart run build_runner build --delete-conflicting-outputs

# 5. Run
flutter run
```

## Project structure

```
lib/
├── app/                 # Entry point + router
├── core/
│   ├── theme/           # Design system: colors, typography, theme
│   ├── animation/       # Motion tokens + transitions
│   ├── network/         # OpenRouter service + food nutrition DB
│   └── config/          # Secrets (gitignored)
├── data/
│   ├── models/          # FoodItem, Meal, DailyLog
│   ├── sources/         # Hive local cache
│   └── repositories/    # Orchestration: cache → API → save
├── features/
│   ├── home/            # Daily dashboard with progress ring
│   ├── camera/          # Camera capture + compression
│   └── review/          # AI result review + edit + save
└── shared/
    ├── widgets/         # Reusable UI: CalorieRing, MacroBar, MealCard
    └── providers/       # Riverpod providers
```

## How the AI works

1. **Image captured** → compressed client-side to ~800KB
2. **Quick hash lookup** → if seen before, return cached items instantly
3. **OpenRouter → MiniMax M3** → JSON response with structured food items
4. **USDA enrichment** → items enriched with calories/macros from local DB
5. **User reviews** → edits portions if needed, logs meal
6. **Cached for next time** → image hash + items stored locally

Cost per meal recognition: **~$0.0005**. Cache hit rate target: **60% by month 6**.

## Roadmap

- [x] Bare-bones MVP (no auth)
- [ ] Apple Sign-In / Google Sign-In
- [ ] Cloud sync (PocketBase)
- [ ] Barcode scanner
- [ ] Manual food search
- [ ] Macro tracking (premium)
- [ ] AI nutrition coach (premium)
- [ ] Apple Health / Google Fit integration

## License

MIT — see [LICENSE](LICENSE).