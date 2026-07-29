# Architecture

Little Wonder World uses a **feature-based clean architecture**: every screen or capability is a
folder under `lib/features/`, built on shared frameworks in `lib/shared/` and infrastructure in
`lib/core/`. Rendering is strictly separated from game rules so that the rules stay pure Dart and
unit-testable.

## Directory map

```
lib/
  main.dart                     Entry point: landscape lock, immersive UI, bootstrap AppServices
  app/
    app.dart                    Root widget: provider wiring, lifecycle observer, MaterialApp
    app_services.dart           Builds/owns every controller; resetProgress / deleteAllData
  config/
    app_config.dart             Product name, default PIN, gate hold time, touch-target minimum,
                                escalation thresholds, data schema version
  core/
    accessibility/app_haptics.dart    Optional, always-gentle haptic feedback
    audio/                            AudioManager (music/effects/voice), SoundEffect + MusicTrack
                                      ids, VoiceInstruction ids + VoiceCatalog file resolution
    localization/                     (reserved; generated l10n lives in lib/l10n)
    navigation/app_navigation.dart    GentlePageRoute: soft fades, instant under reduced motion
    persistence/                      LocalStore, JsonDocument envelope, DataMigrator
    theme/                            Palette (warm pastels) + AppTheme (parent/child themes)
  features/
    child_home/                 Milo welcome screen, big play button, corner-gate overlay
    world_map/                  Six-location game selection map
    feed_animals/               Mini-game 1: drag food to farm animals (+ animal_art.dart)
    bubble_pop/                 Mini-game 2
    dancing_socks/              Mini-game 3
    muddy_pig/                  Mini-game 4
    build_rocket/               Mini-game 5
    bedtime_routine/            Mini-game 6
    sticker_book/               Drag-to-place sticker album (3 scenes), placement persistence
    rewards/                    RewardData, RewardsController, StickerCatalog, RewardOverlay
    parent_gate/                ParentCornerGate (two-corner 3 s hold) + PinScreen
    parent_dashboard/           Dashboard screen + sections/ (profile, games, session,
                                progress, settings) + GameAccess model/controller
    profiles/                   ChildProfile model + controller (nickname, age group, stage...)
    session_control/            SessionController state machine, SessionConfig/Usage, SleepyScreen
    progress/                   Neutral per-game statistics (ProgressData + controller)
    settings/                   AppSettings model + controller (audio, motion, contrast, PIN...)
  shared/
    characters/                 MiloState, MiloPainter (procedural art), MiloComponent (Flame),
                                MiloView (widget)
    components/                 DraggableItem, DropZone, TapTarget, SwipeCleanLayer,
                                gentle_effects (pulse/sparkle/glow)
    game/                       ToddlerGame base class, GameContext, GameRegistry, MiniGameScreen
    models/                     GameId, DevelopmentStage + StageConfig, Skill
    widgets/                    BigRoundButton, StickerArtView, WorldIcon
  l10n/                         app_en.arb, app_ar.arb + generated AppLocalizations
assets/
  audio/music|effects|voices/en|voices/ar    Generated placeholder WAVs (tool/gen_audio.py)
  images/, sprites/                          Empty until real artwork arrives
  config/placeholder_assets.txt              Pointer to the asset guides
tool/gen_audio.py               Synthesizes all placeholder audio
```

## Separation of concerns

| Concern | Lives in | Never touches |
|---|---|---|
| Rendering | Flame components / CustomPainters (`shared/characters`, `shared/components`, per-game files) | Persistence, providers, navigation |
| Game rules | `ToddlerGame` subclasses + `StageConfig` values | Widgets, storage, `BuildContext` |
| Input | Flame `TapCallbacks`/`DragCallbacks` on shared components (touch-down activation, padded hit areas) | Business state |
| Audio | `AudioManager` behind the `GameAudio` interface | Game logic (games only emit ids) |
| Persistence | `LocalStore` + `JsonDocument` repositories per feature | UI |
| Rewards | `RewardsController`, `StickerCatalog`, `RewardOverlay` | Game internals (triggered by the wrapper) |
| Difficulty | `StageConfig` data (see below) | Game code branching on the stage enum |
| Localization | ARB files + `AppLocalizations`; voice ids resolved by `VoiceCatalog` | Hard-coded strings |
| Parent settings | `SettingsController`, `GameAccessController`, `SessionController` | Child screens mutating them |

Games receive everything they are allowed to know through **`GameContext`**
(`lib/shared/game/game_context.dart`): stage config, a `GameAudio`, haptics, accessibility flags
(`reducedMotion`, `highContrast`, `leftHanded`), and two callbacks (`onHintShown`,
`onCompleted`). Games never import providers, repositories, or navigation — that is the
boundary that keeps them unit-testable with `NoopGameAudio`.

## Data flow

```
main.dart
  └─ AppServices.bootstrap()          one instance per run; opens SharedPreferencesStore,
      │                               builds + init()s every controller, wires audio<->settings
      └─ LittleWonderApp (lib/app/app.dart)
           ├─ MultiProvider           exposes each ChangeNotifier controller
           ├─ WidgetsBindingObserver  app pause/resume -> AudioManager + SessionController
           └─ MaterialApp(home: ChildHomeScreen, locale from SettingsController)
```

- **Provider controllers.** `SettingsController`, `ProfileController`, `GameAccessController`,
  `ProgressController`, `RewardsController`, `StickerBookController`, and `SessionController` are
  `ChangeNotifier`s created once in `AppServices` and exposed via `MultiProvider`. Screens
  `watch`/`read` them; each controller persists through its repository.
- **MiniGameScreen orchestration** (`lib/shared/game/mini_game_screen.dart`): builds the
  `GameContext` from profile + settings, creates the game via `GameRegistry.of(id).create(...)`,
  records `recordGameStarted`, and wraps the `GameWidget` in an **LTR `Directionality`** (game
  scenes are never mirrored) plus an always-available home bubble. On `onCompleted` it runs the
  reward flow: `RewardsController.awardCompletion` → `ProgressController.recordCompletion`
  (skills, hints used, play time) → `RewardOverlay` dialog → leave.
- **Session wind-down.** `SessionController` is a five-phase state machine
  (`ready → running → windDown → sleepy → blocked/ready`). While `running`, a 1-second tick
  accumulates play time; `AppConfig.sessionEndWarning` (1 min) before the limit it fires
  `onWarning` (soft reminder sound, wired in `app.dart`). When time elapses **mid-activity** the
  phase becomes `windDown` — nothing interrupts the child. When the activity finishes,
  `MiniGameScreen._leaveAfterActivity` calls `finishWindDown()` and replaces the route with
  `SleepyScreen` (sleepy Milo, lullaby). New sessions stay blocked until the configured break
  passes, a new day starts, or a parent unlocks (`parentAllowExtraSession`). App pauses commit
  elapsed time so a kill loses nothing; ticks ignore large clock gaps so device sleep is not
  counted as play.

## Persistence design

- **`LocalStore`** (`lib/core/persistence/local_store.dart`): a minimal key-value interface.
  Production uses `SharedPreferencesStore` (every key prefixed `lww.`); tests use
  `InMemoryStore`. Swapping storage engines later touches only this file. `clearAll()` backs the
  parent's "Delete all child data".
- **`JsonDocument<T>`** (`json_document.dart`): each feature repository stores one versioned JSON
  envelope per key: `{"v": <schemaVersion>, "data": {...}}`. On load, older versions run through
  `DataMigrator` **before** decoding, so model classes only ever see the current schema. Corrupt
  documents (`FormatException`/`TypeError`) fall back to defaults instead of crashing the child's
  app.
- **`DataMigrator`** (`data_migrator.dart`): a stepwise `fromVersion → fromVersion + 1` pipeline
  keyed by `storeKey`. The MVP ships schema version 1 (`AppConfig.dataSchemaVersion`), so the
  pipeline is empty but in place — bump the constant and add a `_step` case when a model changes.

Store keys: `settings`, `profile`, `game_access`, `progress`, `rewards`, `sticker_book`,
`session_config`, `session_usage`.

## Stage system

Three parent-selectable `DevelopmentStage`s (`explorer`, `helper`, `littleThinker`). **Behaviour
is data**: each stage maps to a `StageConfig` (`lib/shared/models/development_stage.dart`) and
games read those values — they never branch on the enum for tunables, so balance changes happen
in one file.

| StageConfig field | Explorer | Helper | Little Thinker |
|---|---|---|---|
| `hintDelay` (idle time before an automatic hint) | 3 s | 5 s | 7 s |
| `maxActiveTargets` (simultaneous correct targets) | 1 | 2 | 3 |
| `distractorCount` (wrong-choice items) | 0 | 1 | 2 |
| `puzzlePieceCount` (rocket pieces) | 2 | 3 | 4 |
| `maxCountingNumber` (0 = no counting) | 0 | 0 | 3 |
| `routineStepCount` (pig bath / bedtime steps) | 1 | 2 | 5 |
| `usesSequences` (ordered mini-sequences) | no | no | yes |
| `itemScale` (object size multiplier) | 1.25 | 1.1 | 1.0 |

Optional gentle auto-progression (never speed-based) advances the stage after several relaxed,
hint-free completions (`ProgressData.relaxedCompletionStreak`, toggled per profile).

## Reusable systems (shared by all mini-games)

- **Drag-and-drop with generous snapping** — `DraggableItem` + `DropZone`
  (`lib/shared/components/`); `ToddlerGame.resolveDrop` finds the nearest enabled zone within its
  `snapRadius` (default: half the zone size + 60 px). Wrong zone → escalation ladder; empty space
  → the item just drifts home with no sound (not counted as a mistake).
- **Tap targets** — `TapTarget`: reacts on touch-**down** (no release precision or double taps),
  pads its hit area by 24 px, supports pulse/highlight hints.
- **Swipe-clean layer** — `SwipeCleanLayer`: wipeable soft "dirt" blobs with a very generous
  erase radius; progress/finished callbacks; used by Muddy Pig Bath, generic for any
  clean-the-surface activity.
- **Hint countdown** — `ToddlerGame.startHintCountdown` fires `showHint()` after
  `StageConfig.hintDelay` of inactivity and repeats gently until the child acts; every hint is
  reported through `GameContext.onHintShown` for the parent's progress view.
- **Wrong-attempt escalation ladder** — `ToddlerGame.handleWrongAttempt`, thresholds in
  `AppConfig`: soft bounce-back always; replay the instruction after 2 attempts; highlight the
  destination after 3; auto-assist after 4 (then the counter resets). No error symbols, no
  negative sounds.
- **Milo states** — 8 `MiloState`s (idle, talking, pointing, happy, laughing, surprised,
  dancing, sleepy) rendered by `MiloPainter`, hosted by `MiloComponent` (Flame) and `MiloView`
  (widgets); `ToddlerGame.say()` plays a voice line while Milo talks.
- **Reward flow** — `completeGame()` celebrates (effect + voice + dancing Milo), then
  `MiniGameScreen` awards a star and the next sticker for that game (`StickerCatalog`), records
  neutral progress, shows `RewardOverlay`, and returns to the map — or into wind-down when the
  session ended meanwhile.
