# Little Wonder World

> Working title — the product name lives in `lib/config/app_config.dart` (`AppConfig.appName`).

An **offline-first Android toddler game** (ages 2–3) built with **Flutter + Flame**. Six gentle
mini-games guide the child through a small world with **Milo**, an original friendly animal
character. A PIN-protected **parent dashboard** controls games, session time, and settings, in
**English and Arabic**.

## Child-safety principles (in brief)

- **Everything stays on the device.** No accounts, no ads, no analytics, no tracking, no network
  features. The Android manifest requests **no permissions** (not even `INTERNET`).
- **No way out of the child area by accident.** The parent dashboard sits behind a two-corner
  3-second hold plus a PIN; there are no external links anywhere in the child area.
- **Gentle by design.** No fail states, no error buzzers, no time pressure. Wrong attempts
  escalate softly (bounce back → repeat instruction → highlight → auto-assist) so nobody gets stuck.
- **Session limits with a calm ending.** When time is up, the child finishes the current activity,
  then Milo gets sleepy and the app winds down.
- **Minimal data.** A nickname and an approximate age group only — never real names, birth dates,
  photos, or location. See [PRIVACY_CHECKLIST.md](PRIVACY_CHECKLIST.md).

## Documentation map

| Document | Contents |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Directory map, layering, data flow, persistence, stage system |
| [ASSET_GUIDE.md](ASSET_GUIDE.md) | Placeholder art, painter locations, replacing art with sprites |
| [AUDIO_GUIDE.md](AUDIO_GUIDE.md) | Audio channels, voice/effect/music file IDs, replacing placeholder audio |
| [LOCALIZATION_GUIDE.md](LOCALIZATION_GUIDE.md) | gen-l10n workflow, Arabic RTL rules, adding a language |
| [PARENT_CONTROLS.md](PARENT_CONTROLS.md) | Parent-facing guide to the gate and every dashboard section |
| [PRIVACY_CHECKLIST.md](PRIVACY_CHECKLIST.md) | What is (and is not) stored; pre-release legal review list |
| [GOOGLE_PLAY_RELEASE_CHECKLIST.md](GOOGLE_PLAY_RELEASE_CHECKLIST.md) | Everything to do before publishing |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | Running tests, test layout, testing a new mini-game |
| [docs/TODDLER_USABILITY_CHECKLIST.md](docs/TODDLER_USABILITY_CHECKLIST.md) | Manual usability pass with a real device |

## Required software

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | **3.44.8 stable or newer** | Dart 3.12 comes bundled |
| JDK | **17+** | The Android build targets Java 17 (`android/app/build.gradle.kts`) |
| Android SDK | **API 36** | Platform + build-tools; `cmdline-tools` for `sdkmanager`/`avdmanager` |
| Android Studio | optional | Convenient for emulators and profiling; the CLI works fine |

Key packages (installed automatically from `pubspec.yaml`): Flame 1.38, provider,
shared_preferences, audioplayers, flutter_localizations + intl.

## Flutter setup

1. Install Flutter 3.44.8+ ([docs.flutter.dev/get-started](https://docs.flutter.dev/get-started))
   and add `flutter` to your `PATH`.
2. Install the Android SDK (via Android Studio or `sdkmanager`), including platform **android-36**.
3. Point Flutter at the SDK if needed: `flutter config --android-sdk <path>`.
4. Accept licenses: `flutter doctor --android-licenses`.
5. Verify: `flutter doctor` — the *Flutter* and *Android toolchain* sections must be green.

## Package installation

```bash
flutter pub get
```

Localizations are **generated automatically on every build** (`generate: true` in `pubspec.yaml`
plus `l10n.yaml`). To regenerate them by hand (for example after editing an ARB file, so your IDE
picks up new getters immediately):

```bash
flutter gen-l10n
```

## Running the app

On an emulator:

```bash
flutter emulators                          # list configured emulators
flutter emulators --launch <emulator_id>   # boot one
flutter run
```

On a physical device: enable *Developer options → USB debugging*, plug the device in, confirm it
appears in `flutter devices`, then `flutter run` (use `-d <device_id>` when several devices are
connected).

The child area runs **landscape** with sticky-immersive system UI (set in `lib/main.dart`); the
parent dashboard temporarily re-enables portrait while it is open. The app is fully offline — no
network setup is required.

## Running tests

```bash
flutter test                    # all unit and widget tests (no device needed)
flutter test integration_test   # on-device integration smoke test (device/emulator required)
```

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for the test layout and patterns (in-memory store,
`NoopGameAudio`, manual session ticking, and why `pumpAndSettle` must be avoided around Milo).

## Building a debug APK

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`. Install with
`adb install -r build/app/outputs/flutter-apk/app-debug.apk` or just use `flutter install`.

## Building a release Android App Bundle

> **Before any release build:** change the application ID — the project still ships the
> placeholder `com.example.little_wonder_world`, which Google Play rejects. See
> [Changing the application name and package identifier](#changing-the-application-name-and-package-identifier).

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

Release builds must be signed with **your own upload keystore**; the checked-in config currently
falls back to debug signing (see the `TODO` in `android/app/build.gradle.kts`). Create a keystore
and a `key.properties`-based signing config following the official guide:
<https://docs.flutter.dev/deployment/android#sign-the-app>. The full pre-publish list is in
[GOOGLE_PLAY_RELEASE_CHECKLIST.md](GOOGLE_PLAY_RELEASE_CHECKLIST.md).

## Replacing placeholder assets

Every visual is procedurally drawn and every sound is synthesized — deliberately, so that real
artwork and recordings can replace them **without code changes**:

- Art (painters, sprite swap points, art direction rules): [ASSET_GUIDE.md](ASSET_GUIDE.md)
- Audio (file naming, regeneration, recording guidance): [AUDIO_GUIDE.md](AUDIO_GUIDE.md)

## Adding another mini-game

1. **Create a feature directory** `lib/features/<your_game>/` with a `ToddlerGame` subclass
   (see `lib/shared/game/toddler_game.dart`). Implement `showHint`, `repeatInstruction`,
   `highlightTarget`, and `autoAssist`; call `registerCorrectAction` / `handleWrongAttempt` /
   `completeGame` from your interactions. Read all difficulty tunables from `stage`
   (`StageConfig`) — never hard-code counts or sizes.
2. **Add a `GameId` value** in `lib/shared/models/game_id.dart` with a stable `storageKey`
   (never rename existing keys without a `DataMigrator` step).
3. **Register it in `GameRegistry`** (`lib/shared/game/game_registry.dart`): id, practised
   `Skill`s, localized title getter, and the game factory. The world map, parent game-access
   settings, and `MiniGameScreen` all pick it up from there automatically.
4. **Add `VoiceInstruction` ids** for the game's spoken prompts in
   `lib/core/audio/voice_catalog.dart`, then regenerate placeholder audio so files exist for every
   id in every language: `python3 tool/gen_audio.py`.
5. **Add the l10n title** (`game<YourGame>`) to `lib/l10n/app_en.arb` **and** `app_ar.arb`, then
   `flutter gen-l10n`.
6. **Add stickers** for the game in `StickerCatalog`
   (`lib/features/rewards/sticker_catalog.dart`) — three per game keeps parity — plus their
   drawings in `lib/shared/widgets/sticker_art.dart`, and a world-map tile in
   `lib/shared/widgets/world_icon.dart`.
7. **Write tests**: pure game-rule tests using `GameContext` + `NoopGameAudio`, and a widget/
   integration pass. See [TESTING_GUIDE.md](TESTING_GUIDE.md).

## Adding another language

1. Create `lib/l10n/app_<code>.arb` (copy `app_en.arb`, translate every key).
2. Add the code to `VoiceCatalog.supportedLanguages` in `lib/core/audio/voice_catalog.dart`.
3. Provide voice clips under `assets/audio/voices/<code>/` — one WAV per `VoiceInstruction`
   (snake_case file names; run `python3 tool/gen_audio.py` after extending it with the new
   language for placeholders, or drop in real recordings).
4. Add `- assets/audio/voices/<code>/` to the `assets:` list in `pubspec.yaml`.
5. Run `flutter gen-l10n` and offer the language in the profile/settings language pickers.

Full details (including RTL rules): [LOCALIZATION_GUIDE.md](LOCALIZATION_GUIDE.md).

## Changing the application name and package identifier

"Little Wonder World" and `com.example.little_wonder_world` are placeholders. To rename:

| What | Where |
|---|---|
| Display name used inside the app | `AppConfig.appName` in `lib/config/app_config.dart` |
| Android launcher label | `android:label` in `android/app/src/main/AndroidManifest.xml` |
| Package identifier | `applicationId` **and** `namespace` in `android/app/build.gradle.kts` |

If you change the `namespace`, keep the Kotlin `MainActivity` package
(`android/app/src/main/kotlin/...`) in sync. Changing the `applicationId` after publishing creates
a *different app* on Google Play — settle it before the first release.
