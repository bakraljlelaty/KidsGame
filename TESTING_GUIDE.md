# Testing Guide

## Running tests

```bash
flutter test                      # all unit + widget tests, no device needed
flutter test test/features/       # one area
flutter test integration_test     # device integration test (emulator or physical device)
```

The integration test uses the `integration_test` package (already in `dev_dependencies`) and
must run on a real device or emulator — it exercises the app end-to-end (boot, gate, a game,
reward flow) rather than isolated units.

## Test layout and what each area covers

| Location | Covers |
|---|---|
| `test/core/` | Infrastructure: `LocalStore` implementations, `JsonDocument` envelope + corrupt-data fallback, `DataMigrator` steps, `VoiceCatalog` id/path mapping, sound/music asset paths |
| `test/features/` | Controller and rules logic per feature: `SessionController` phases/limits/breaks, `SettingsController` (PIN change/check, restore-defaults keeping the PIN), `ProgressController` neutral counting, `RewardsController` star/sticker awards, `GameAccess` (de)serialization, profile stage handling — plus the academy suite below |
| `test/shared/` | The shared game framework: `ToddlerGame` hint countdown + escalation ladder, `resolveDrop` snapping, `StageConfig` values, Milo state transitions |
| `test/widgets/` | Widget tests: parent corner gate + PIN screen, dashboard sections reacting to controllers, reward overlay, child home phases (ready/resting), and navigation through the v2 academy structure |
| `integration_test/` | On-device smoke: full bootstrap with real `SharedPreferences`, navigating home → rooms → a game → completion → reward |

### The academy (v2) test files

| File | Covers |
|---|---|
| `test/features/age_band_test.dart` | `AgeBand` storage keys, `BandConfig` values per band, legacy-stage mapping in both directions |
| `test/features/migration_v2_test.dart` | The `DataMigrator` 1 → 2 step: v1 `stage`/`ageGroup` profiles migrate to the right `band`, other documents survive untouched |
| `test/features/activity_definitions_test.dart` | Catalog integrity: unique stable spec ids, valid content packs, per-band subject availability (`subjectsFor`), `byId` lookup |
| `test/features/path_progress_test.dart` | `PathProgressController`: in-order unlock rules, `nextNode`, per-band node keys, unit-badge award, persistence across reload, reset |
| `test/features/academy_rewards_progress_test.dart` | Subject-keyed rewards (`awardActivityCompletion`, subject stars, unit-completion stickers) and subject-keyed `ProgressData` recording |
| `test/widgets/world_map_access_test.dart`, `test/widgets/smoke_complete_game_test.dart` | Widget tests that exercise the academy screens: home → play rooms → Milo's World, game-access gating, and a full completion pass through the v2 structure |

Every layer was built for testability — use these seams instead of mocking frameworks:

- `InMemoryStore` (`lib/core/persistence/local_store.dart`) replaces SharedPreferences.
- `NoopGameAudio` (`lib/core/audio/audio_manager.dart`) records every effect/instruction id it
  was asked to play — assert on `noop.effects` / `noop.instructions`.
- `AppServices.bootstrap(store: InMemoryStore(), enableAutoTick: false, initAudio: false)` gives
  a fully wired app without platform channels, real timers, or audio players.
- `SessionController` takes an injectable `clock` and, with `enableAutoTick: false`, is driven by
  calling `tick()` manually — no fake `Timer`s needed.

## Testing a new activity engine or mini-game

**1. Pure rules first (no widgets, no Flame mounting needed for most logic).** Construct the game
with a hand-built `GameContext`:

```dart
final audio = NoopGameAudio();
var hints = 0;
var completed = false;

final game = MyNewGame(GameContext(
  stageConfig: StageConfig.explorer,     // v1 tuning (bespoke games)
  bandConfig: BandConfig.twoToThree,     // academy tuning (engines) — test each band
  spec: ActivityDefinitions.colors.first, // for engines: the ActivitySpec under test
  audio: audio,
  onHintShown: () => hints++,
  onCompleted: () => completed = true,
));
```

Then drive the public `ToddlerGame` API: call `handleWrongAttempt()` repeatedly and assert the
escalation order (nothing → instruction replay after 2 → highlight after 3 → auto-assist at 4),
call `registerCorrectAction()` and verify the ladder resets, and check `completeGame()` fires
`onCompleted` exactly once and plays the celebrate effect. Use Flame's `game.update(dt)` to
advance time deterministically — e.g. `update(stage.hintDelay.inSeconds + 0.1)` must trigger
`showHint` and report through `onHintShown`. Assert audio *ids*, never playback:
`expect(audio.instructions, contains(VoiceInstruction.feedIntro))`.

**2. Band/stage behaviour.** For an activity engine, run the same rules against all four
`BandConfig`s (`twoToThree` … `fiveToSix`) and assert counts/sizes/hint delays come from the
config (plus `ActivitySpec.params` overrides via `GameContext.param`); for a bespoke game, do
the same across `StageConfig.explorer` / `helper` / `littleThinker`. A game that hard-codes
tunables is a bug (see ARCHITECTURE.md, "Age bands and BandConfig").

**3. App-level wiring with `enableAutoTick: false`.** For anything touching session flow, build
services in the test:

```dart
final services = await AppServices.bootstrap(
  store: InMemoryStore(),
  clock: () => fakeNow,          // advance fakeNow yourself
  enableAutoTick: false,         // then call services.session.tick() manually
  initAudio: false,              // AudioManager stays a safe no-op
);
```

This lets you simulate "time is up mid-game" (`tick()` until `SessionPhase.windDown`) and assert
the wind-down path without real one-second timers keeping the test alive.

**4. Widget tests — never `pumpAndSettle` with `MiloView` on screen.** `MiloView` runs a
`Ticker` that animates Milo forever, so the frame queue *never settles*;
`tester.pumpAndSettle()` will time out (the same applies to any screen embedding a running
`GameWidget`). Always pump fixed durations instead:

```dart
await tester.pump();                                  // build
await tester.pump(const Duration(milliseconds: 400)); // let animations advance
```

`ChildHomeScreen`, `SleepyScreen`, `RewardOverlay`, `MiniGameScreen`, and `ActivityScreen` all
contain Milo (or a running `GameWidget`) — this rule applies to every test that shows them,
including navigation tests that pass through the learning path or play rooms.

**5. Checklist for the new engine's / game's test file(s)**

- [ ] Completes via its intended interactions; `onCompleted` fired once
- [ ] Hint appears after the configured `hintDelay` idle and repeats; reported via `onHintShown`
- [ ] Wrong-attempt ladder in order, no negative feedback beyond the soft bounce
- [ ] Auto-assist guarantees the child can never be stuck
- [ ] All four `BandConfig`s (engines) / all three `StageConfig`s (bespoke games) change
      counts/sizes as designed
- [ ] Voice ids used exist in `VoiceInstruction` (and files regenerated via `tool/gen_audio.py`)
- [ ] Engines: registered in `ActivityRegistry` and reachable through `ActivitySpec`s in
      `ActivityDefinitions` (stable ids — `activity_definitions_test.dart` guards uniqueness)
- [ ] Bespoke games: registered in `GameRegistry` (title resolves for EN + AR, skills listed,
      the Milo's World map shows it) and stickers exist in `StickerCatalog` so the reward flow
      can award them

## Manual testing

Automated tests cannot judge whether a two-year-old understands the game. Before any release —
and after any change to interaction, audio, or pacing — run the manual pass in
[docs/TODDLER_USABILITY_CHECKLIST.md](docs/TODDLER_USABILITY_CHECKLIST.md) on a real device.
