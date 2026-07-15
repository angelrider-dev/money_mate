# SETUP.md — Run This on Your Local Machine

This code was written in a sandbox that has no Flutter SDK installed, so it has **not been compiled or verified yet**. Follow these steps on your own computer (where Flutter is installed) to turn this into a real, runnable project.

## Step 1 — Create the actual Flutter project

```bash
flutter create moneymate
cd moneymate
```

## Step 2 — Copy these files into place

Replace `pubspec.yaml` with the one provided here, then copy the `lib/data/` folder into your new project's `lib/` folder:

```
moneymate/
├── pubspec.yaml          ← replace with provided version
└── lib/
    └── data/
        ├── local/
        │   ├── database.dart
        │   └── connection.dart
        └── repositories/
            ├── split_calculator.dart
            ├── backup_service.dart
            └── seed_service.dart
```

## Step 3 — Install dependencies

```bash
flutter pub get
```

## Step 4 — Generate Drift code (this creates `database.g.dart`)

```bash
dart run build_runner build --delete-conflicting-outputs
```

If this completes with no errors, the schema is valid and `database.g.dart` will appear next to `database.dart`. **This is the real verification step** — if there are typos or reference errors in the schema, they'll show up here.

## Step 5 — Wire up the seed service in `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase(openConnection());
  await SeedService(db).seedIfNeeded();
  runApp(MyApp(db: db));
}
```

## Common issues to expect

- **Android:** `sqlite3_flutter_libs` needs `minSdkVersion 21+` in `android/app/build.gradle`
- **iOS:** may need `pod install` inside `ios/` after `pub get`
- **image_picker:** requires camera/photo permission entries in `Info.plist` (iOS) and `AndroidManifest.xml` (Android) — Flutter's package docs cover the exact keys needed
- If `build_runner` complains about a table reference before it's defined (e.g. `Accounts` referenced inside `Expenses` which is declared earlier in the file) — Dart doesn't care about declaration order within the same file, so this shouldn't happen, but if it does, it's a quick fix (just reordering class declarations, no logic changes needed)

## After this works

Come back and tell me the `build_runner` output (success or the exact error). If there's an error, paste it here and I'll fix the schema directly — that's the fastest way to close the loop since I can't run it myself in this environment.
