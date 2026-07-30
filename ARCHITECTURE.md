# Architecture

Little Wonder World uses a **feature-based clean architecture**: every screen or capability is a
folder under `lib/features/`, built on shared frameworks in `lib/shared/` and infrastructure in
`lib/core/`. Rendering is strictly separated from game rules so that the rules stay pure Dart and
unit-testable.

Since v2 the app is an **early-learning academy** (ages 2–6): a layer of **reusable activity
engines × data-only content packs** sits on top of the v1 game framework, organised into a
guided **learning path** and free-play **subject rooms**, tuned by four **age bands**. The six
bespoke v1 mini-games live on unchanged inside the *Milo's World* room.

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
  content/                      Pure-data academy content (no widgets, no Flame)
    activity_definitions.dart   ActivityDefinitions: the 5–8 ActivitySpecs per concept area
    items/                      ContentItem model + ItemCatalog packs (colors, shapes, numbers,
                                letters_en, letters_ar, animals, food, vehicles, toys)
    path/learning_path.dart     PathUnit + LearningPath (per-band units/nodes, node keys)
  core/
    accessibility/app_haptics.dart    Optional, always-gentle haptic feedback
    audio/                            AudioManager (music/effects/voice), SoundEffect + MusicTrack
                                      ids, VoiceInstruction ids + VoiceCatalog file resolution
    localization/                     (reserved; generated l10n lives in lib/l10n)
    navigation/app_navigation.dart    GentlePageRoute: soft fades, instant under reduced motion
    persistence/                      LocalStore, JsonDocument envelope, DataMigrator (v1 → v2)
    theme/                            Palette (warm pastels) + AppTheme (parent/child themes)
  features/
    child_home/                 Milo welcome screen, path + rooms buttons, corner-gate overlay
    learning_path/              LearningPathScreen (unit cards, node bubbles) +
                                PathProgressController/-Repository (unlocks, badges)
    play_rooms/                 PlayRoomsScreen (one room per subject) + SubjectRoomScreen
    activities/                 The seven reusable activity engines:
      tap_choice/  drag_sort/  shadow_match/  memory_pairs/
      pattern_complete/  count_and_give/  trace_shape/
    world_map/                  Milo's World room: the six bespoke-game selection map
    feed_animals/               Bespoke game 1: drag food to farm animals (+ animal_art.dart)
    bubble_pop/                 Bespoke game 2
    dancing_socks/              Bespoke game 3
    muddy_pig/                  Bespoke game 4
    build_rocket/               Bespoke game 5
    bedtime_routine/            Bespoke game 6
    sticker_book/               Drag-to-place sticker album (3 scenes), placement persistence
    rewards/                    RewardData, RewardsController, StickerCatalog, RewardOverlay
    parent_gate/                ParentCornerGate (two-corner 3 s hold) + PinScreen
    parent_dashboard/           Dashboard screen + sections/ (profile, games, session,
                                progress, settings) + GameAccess model/controller
    profiles/                   ChildProfile model + controller (nickname, age band, avatar...)
    session_control/            SessionController state machine, SessionConfig/Usage, SleepyScreen
    progress/                   Neutral statistics per game and per subject (ProgressData)
    settings/                   AppSettings model + controller (audio, motion, contrast, PIN...)
  shared/
    characters/                 MiloState, MiloPainter (procedural art), MiloComponent (Flame),
                                MiloView (widget)
    components/                 DraggableItem, DropZone, TapTarget, SwipeCleanLayer,
                                gentle_effects (pulse/sparkle/glow)
    game/                       ToddlerGame base class, GameContext, ActivitySpec + ActivityEngine,
                                ActivityRegistry, ActivityScreen, GameRegistry, MiniGameScreen
    items/item_art.dart         ItemArt: the procedural painter catalog for every ContentItem
    models/                     GameId, AgeBand + BandConfig, DevelopmentStage + StageConfig,
                                Subject, Skill
    widgets/                    BigRoundButton, StickerArtView, WorldIcon, SubjectIcon
  l10n/                         app_en.arb, app_ar.arb + generated AppLocalizations
assets/
  audio/music|effects|voices/en|voices/ar    Generated placeholder WAVs (tool/gen_audio.py)
  images/, sprites/                          Empty until real artwork arrives
  config/placeholder_assets.txt              Pointer to the asset guides
tool/gen_audio.py               Synthesizes all placeholder audio
```

## The academy layer: engines × content packs

Production breadth comes from separating *how you play* from *what you play with*. Seven
reusable **activity engines** (Flame games on the v1 `ToddlerGame` base, under
`lib/features/activities/`) run on data-only **content packs** (`ItemCatalog`,
`lib/content/items/item_catalog.dart`):

| Engine | Interaction | Used by subjects (per `ActivityDefinitions`) |
|---|---|---|
| `TapChoice` (`tap_choice`) | tap the right one of N; modes: find-it, odd-one-out (`oddOneOut`), how-many (`countMode`) | colors, shapes, animals, food, numbers, letters |
| `DragSort` (`drag_sort`) | drag items into 2–3 bins (by `ContentItem.group` / color) | colors, shapes, animals, food |
| `ShadowMatch` (`shadow_match`) | drag each object onto its silhouette | shapes, animals, food, letters |
| `MemoryPairs` (`memory_pairs`) | flip cards, find matching pairs | colors, shapes, animals, food, numbers, letters |
| `PatternComplete` (`pattern_complete`) | pick what comes next in an AB/ABC/AABB pattern | colors, shapes, animals, food, numbers |
| `CountAndGive` (`count_and_give`) | give N items to a character | colors, animals, food, numbers |
| `TraceShape` (`trace_shape`) | finger-trace a guided outline | shapes, numbers, letters |
| bespoke (`bespoke`) | the six full v1 mini-games via `GameRegistry` | milosWorld (no content pack) |

- **`ActivitySpec`** (`lib/shared/game/activity_spec.dart`) is the pure-data contract joining
  the two: a stable persisted `id`, an `ActivityEngine`, a `Subject`, a `contentPack` name,
  practised `Skill`s, and optional integer `params` (engine modes and per-node difficulty
  overrides such as `'rounds'`, `'pairs'`, `'oddOneOut'`). Bespoke specs carry a `bespokeGame`
  `GameId` instead of a pack.
- **`ActivityDefinitions`** (`lib/content/activity_definitions.dart`) is the activity catalog:
  5–8 specs per concept area (`Subject`: colors, shapes, animals, food, numbers, letters,
  milosWorld). `subjectsFor(band)` hides the letters subject in bands where
  `BandConfig.lettersEnabled` is false.
- **`ActivityRegistry`** (`lib/shared/game/activity_registry.dart`) maps a spec to a running
  game — one `switch` over `ActivityEngine`, delegating `bespoke` to the v1 `GameRegistry`.
- **`ActivityScreen`** (`lib/shared/game/activity_screen.dart`) hosts one activity the same way
  `MiniGameScreen` hosts a v1 game: builds the `GameContext`, records subject progress, marks
  the learning-path node on completion, runs the reward flow, and respects session wind-down.

**The `GameContext` boundary** (`lib/shared/game/game_context.dart`) still holds: engines
receive *everything* through it — `bandConfig` (academy tuning), `stageConfig` (v1 tuning for
bespoke games), the optional `spec`, `languageCode` (so the `'letters'` pack resolves per
language), audio/haptics/accessibility, and the `onHintShown`/`onCompleted` callbacks. Engines
never touch persistence, providers, or navigation, and read per-spec overrides through
`GameContext.param(key, fallback)`.

## Learning path and play rooms

Two entry points from the child home (`lib/features/child_home/`): the **guided path** and the
**free-play rooms** (`lib/features/play_rooms/play_rooms_screen.dart` — one room per subject;
the Milo's World room opens the v1 `WorldMapScreen`).

- **Definition** (`lib/content/path/learning_path.dart`): `LearningPath.unitsFor(band)` builds
  one `PathUnit` per subject available in the band (unit id
  `<band.storageKey>_<subject.storageKey>`), whose nodes are that subject's `ActivitySpec`s.
  Content repeats across bands at each band's own difficulty, so moving up feels familiar.
- **Per-band progress keys**: a completed node is stored as
  `LearningPath.nodeKey(band, spec)` = `<band.storageKey>/<spec.id>` — progress in one band
  never unlocks another band's path.
- **`PathProgressController`** (`lib/features/learning_path/path_progress.dart`) owns the
  rules, persisted as the `path_progress` document (`completedNodeKeys` + `unitBadges`):
  - *Unlocking*: a node is playable when every node before it (across units, in path order) is
    complete — or when it is itself already complete (free replay). `nextNode(band)` is the
    single "play next" target the path screen highlights.
  - *Badges*: `markNodeCompleted` returns the `PathUnit` if that completion finished the unit,
    which triggers the badge celebration; badges are stored per unit id.
  - *Free play counts*: `ActivityScreen` calls `markNodeCompleted` no matter where the activity
    was launched from, so playing in a room gently advances the path too.
  - Reset (`reset()`) is wired to the parent dashboard's reset-progress action.

## Age bands and BandConfig

Four parent-selectable `AgeBand`s — `twoToThree`, `threeToFour`, `fourToFive`, `fiveToSix`
(`lib/shared/models/age_band.dart`) — supersede the v1 three-stage system for all academy
tuning. **Behaviour is data**: each band maps to a `BandConfig` and engines read those values,
never branching on the enum.

| BandConfig field | 2–3 | 3–4 | 4–5 | 5–6 |
|---|---|---|---|---|
| `hintDelay` | 3 s | 5 s | 6 s | 7 s |
| `choiceCount` | 2 | 3 | 4 | 4 |
| `memoryPairCount` | 2 | 3 | 4 | 6 |
| `patternLength` / `patternChoices` | 2 / 2 | 2 / 3 | 3 / 3 | 4 / 4 |
| `countingMax` | 3 | 5 | 7 | 10 |
| `sortBinCount` / `sortItemCount` | 2 / 4 | 2 / 6 | 3 / 6 | 3 / 9 |
| `itemScale` | 1.25 | 1.1 | 1.0 | 0.95 |
| `lettersEnabled` | no | yes | yes | yes |
| `traceDetail` | 1 | 1 | 2 | 3 |

The v1 `DevelopmentStage`/`StageConfig` survives for the six bespoke games:
`AgeBand.legacyStage` derives the stage they still read (2–3 → explorer, 3–4 → helper,
4–5 and 5–6 → littleThinker), and `AgeBand.fromLegacyStage` maps the other way for storage
migration. Per-spec `params` may override individual `BandConfig` values node by node.

## Separation of concerns

| Concern | Lives in | Never touches |
|---|---|---|
| Rendering | Flame components / CustomPainters (`shared/characters`, `shared/components`, `shared/items/item_art.dart`, per-game files) | Persistence, providers, navigation |
| Game rules | `ToddlerGame` subclasses + `BandConfig` (engines) / `StageConfig` (bespoke) values | Widgets, storage, `BuildContext` |
| Teachable content | `ContentItem` packs in `ItemCatalog` + `ActivitySpec`s in `ActivityDefinitions` (pure data under `lib/content/`) | Engine internals, rendering |
| Input | Flame `TapCallbacks`/`DragCallbacks` on shared components (touch-down activation, padded hit areas) | Business state |
| Audio | `AudioManager` behind the `GameAudio` interface | Game logic (games only emit ids) |
| Persistence | `LocalStore` + `JsonDocument` repositories per feature | UI |
| Rewards | `RewardsController`, `StickerCatalog`, `RewardOverlay` | Game internals (triggered by the wrapper) |
| Difficulty | `BandConfig` / `StageConfig` data (see above) | Game code branching on the band/stage enums |
| Localization | ARB files + `AppLocalizations`; voice ids resolved by `VoiceCatalog` | Hard-coded strings |
| Parent settings | `SettingsController`, `GameAccessController`, `SessionController` | Child screens mutating them |

Games receive everything they are allowed to know through **`GameContext`**
(`lib/shared/game/game_context.dart`): band + stage config, the `ActivitySpec` being played
(null when a bespoke game is launched directly from Milo's World), the language code, a
`GameAudio`, haptics, accessibility flags (`reducedMotion`, `highContrast`, `leftHanded`), and
two callbacks (`onHintShown`, `onCompleted`). Games never import providers, repositories, or
navigation — that is the boundary that keeps them unit-testable with `NoopGameAudio`.

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
  `ProgressController`, `PathProgressController`, `RewardsController`, `StickerBookController`,
  and `SessionController` are `ChangeNotifier`s created once in `AppServices` and exposed via
  `MultiProvider`. Screens `watch`/`read` them; each controller persists through its repository.
- **ActivityScreen orchestration** (`lib/shared/game/activity_screen.dart`): builds the
  `GameContext` from profile + settings + the `ActivitySpec`, creates the game via
  `ActivityRegistry.create(spec, context)`, records the start (per subject for engines, per
  `GameId` for bespoke), and wraps the `GameWidget` in an **LTR `Directionality`** (game scenes
  are never mirrored) plus an always-available home bubble. On `onCompleted` it runs the reward
  flow: `PathProgressController.markNodeCompleted` (badge check) →
  `RewardsController.awardActivityCompletion` (subject star; or `awardCompletion` for bespoke)
  → `ProgressController.recordActivityCompletion` (skills, hints used, play time) →
  `RewardOverlay` dialog → leave. `MiniGameScreen` (`mini_game_screen.dart`) still does the
  equivalent for bespoke games opened directly from the Milo's World map.
- **Session wind-down.** `SessionController` is a five-phase state machine
  (`ready → running → windDown → sleepy → blocked/ready`). While `running`, a 1-second tick
  accumulates play time; `AppConfig.sessionEndWarning` (1 min) before the limit it fires
  `onWarning` (soft reminder sound, wired in `app.dart`). When time elapses **mid-activity** the
  phase becomes `windDown` — nothing interrupts the child. When the activity finishes,
  `ActivityScreen`/`MiniGameScreen` `_leaveAfterActivity` calls `finishWindDown()` and replaces
  the route with `SleepyScreen` (sleepy Milo, lullaby). New sessions stay blocked until the configured break
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
  keyed by `storeKey`. v2 ships schema version 2 (`AppConfig.dataSchemaVersion`) with the first
  real step, **1 → 2**: on the `profile` document the v1 `stage` + `ageGroup` fields are
  replaced by a single `band` (`explorer` → `two_three`, `helper` → `three_four`,
  `little_thinker` → `four_five`; a stage-less v1 profile falls back to the age group). All
  other v1 documents (progress, rewards, stickers, session data) are kept as-is — nothing is
  lost on upgrade.

Store keys: `settings`, `profile`, `game_access`, `progress`, `rewards`, `sticker_book`,
`session_config`, `session_usage`, and (new in v2) `path_progress`.

## Subject-keyed progress and rewards

Statistics and rewards are recorded per concept area, alongside the v1 per-game records:

- **`ProgressData`** (`lib/features/progress/progress_data.dart`) holds `games`
  (`Map<GameId, GameProgress>`, bespoke) **and** `subjects` (`Map<Subject, GameProgress>`,
  academy activities) plus `skillPlays`. `ActivityScreen` routes engine activities to
  `recordActivityStarted/Hint/Completion(subject)` and bespoke games to the v1 per-game
  methods. Totals aggregate across both maps; the parent progress section lists played
  subjects with their `SubjectIcon`.
- **`RewardData`** (`lib/features/rewards/reward_data.dart`) adds `subjectStars`
  (`Map<Subject, int>`, serialized by `Subject.storageKey`). `awardActivityCompletion(subject,
  unitCompleted:)` grants a subject star and — when a learning-path unit was just finished — the
  next unearned sticker; bespoke completions keep the v1 per-game star/sticker flow.

## Stage system (v1 legacy, still used by the six bespoke games)

The v1 three-stage system (`DevelopmentStage`: `explorer`, `helper`, `littleThinker`, in
`lib/shared/models/development_stage.dart`) is no longer parent-facing — parents pick an age
band, and `AgeBand.legacyStage` derives the stage the bespoke games still read. As with bands,
**behaviour is data**: each stage maps to a `StageConfig` and games read those values.

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

`ProgressData.relaxedCompletionStreak` (completions without hints) remains the input for
gentle, never speed-based automatic progression.

## Reusable systems (shared by engines and mini-games)

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
