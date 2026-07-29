# Little Wonder World — Implementation Plan

Working title configured in `lib/config/app_config.dart` (`AppConfig.appName`).

## Goal

An offline-first, Android-first Flutter + Flame toddler game (ages 2–3) with six
mini-games, an original guide character (Milo), three development stages, a
PIN-protected parent dashboard, session-time controls, local-only persistence,
rewards + sticker book, and English/Arabic localization.

## Toolchain

| Tool | Version |
|---|---|
| Flutter | 3.44.8 stable |
| Dart | 3.12.2 (null safety) |
| Flame | 1.38.x |
| provider | 6.x (state management) |
| shared_preferences | 2.x (local persistence) |
| audioplayers | 6.x (music / effects / voice channels) |
| flutter_localizations + gen-l10n | EN + AR |

No backend, no analytics, no ads, no network permissions used by the app.

## Architecture

Feature-based clean architecture. Rendering (Flame components / widgets) is
separated from game rules (pure Dart, unit-testable), input handling, audio,
persistence, rewards, difficulty configuration, and localization.

```
lib/
  main.dart
  app/                    root widget, provider wiring, lifecycle observer
  config/                 app_config.dart (product name, default PIN, tunables)
  core/
    audio/                AudioManager, VoiceCatalog (instruction IDs -> files)
    localization/         locale controller (l10n ARB files live in lib/l10n)
    navigation/           route names + helpers
    persistence/          LocalStore abstraction, JSON repositories, migration
    theme/                warm pastel palette, parent/child themes
    accessibility/        semantics helpers, motion/contrast settings surface
  features/
    child_home/           Milo welcome screen, big play button, corner gate
    world_map/            six-location world selection
    feed_animals/         mini-game 1
    bubble_pop/           mini-game 2
    dancing_socks/        mini-game 3
    muddy_pig/            mini-game 4
    build_rocket/         mini-game 5
    bedtime_routine/      mini-game 6
    sticker_book/         offline sticker album with drag-to-place scenes
    rewards/              stars, stickers, decoration progress, reward overlay
    parent_gate/          two-corner 3s hold + PIN pad
    parent_dashboard/     profile, game access, session, progress sections
    profiles/             child profile model/controller
    session_control/      session timer, daily limit, break, wind-down flow
    progress/             neutral-wording progress tracking
    settings/             audio/motion/contrast/haptics/language/data controls
  shared/
    characters/           Milo painter + Flame component + widget (8 states)
    components/           DraggableItem, DropZone, TapTarget, SwipeCleaner,
                          snapping, hint highlight, gentle particles
    game/                 ToddlerGame base, GameContext, hint controller,
                          wrong-attempt escalation, MiniGameScreen wrapper,
                          GameRegistry
    models/               GameId, DevelopmentStage + StageConfig, Skill
    widgets/              big round buttons, icon labels, star displays
assets/
  audio/music|effects|voices/en|voices/ar   (generated placeholder WAVs)
  config/                 placeholder-asset manifest notes
```

## Key design decisions

1. **Placeholder art is code-drawn.** All art is original vector drawing via
   CustomPainter / Flame canvas rendering. Each drawing lives behind a small
   painter class so sprite sheets can replace it later without touching logic.
2. **Placeholder audio is generated.** A Python script (`tool/gen_audio.py`)
   synthesizes gentle sine-based chimes/loops into WAV files at build-prep
   time; files are committed. Voice clips are per-instruction files named by
   instruction ID so real recordings drop in with no code change.
3. **Stage behaviour is data.** `StageConfig` (per `DevelopmentStage`) carries
   hint delay (3/5/7 s), item counts, distractor counts, puzzle pieces,
   auto-assist thresholds. Games read config; they never branch on stage enum
   directly for tunables.
4. **Wrong attempts are gentle.** Shared escalation: bounce back → replay
   instruction (after 2nd try) → highlight destination (3rd) → auto-assist
   (4th). No error symbols, no negative sounds.
5. **Session wind-down.** When the timer elapses mid-activity the child may
   finish the current mini-game; then the app returns to Milo who is sleepy.
   New sessions blocked until the configured break passes or a parent unlocks.
6. **Persistence.** `LocalStore` interface (SharedPreferences impl,
   in-memory impl for tests); JSON documents carry `schemaVersion` and run
   through `DataMigrator`. One `deleteAllChildData()` wipes everything.
7. **Localization.** gen-l10n ARB files for all parent/child text; spoken
   instructions referenced by `VoiceInstruction` enum, resolved by
   `VoiceCatalog` to `assets/audio/voices/<lang>/<id>.wav`. Arabic parent UI is
   RTL; game scenes are wrapped in LTR and not mirrored.

## Delivery order

1. ✅ Environment inspection, Flutter + Android SDK installation
2. Project skeleton, pubspec, this plan
3. Core systems (theme, persistence, audio, l10n, stage config)
4. Shared game framework + Milo character
5. Parent gate, dashboard, settings, session control, progress
6. Child home, world map, rewards, sticker book
7. Six mini-games (parallel implementation on the shared framework)
8. Tests (unit, widget, integration smoke) + toddler usability checklist
9. Documentation set
10. `flutter analyze` clean → all tests green → debug APK build → push

## Acceptance gates

- App runs offline; all six games playable; three stages behave differently
- Parent settings demonstrably affect the child experience
- Session timer + break enforcement works; progress and stickers persist
- EN + AR parent UI (AR is RTL); no external links in child area
- `flutter analyze` passes; `flutter test` passes; debug APK builds
