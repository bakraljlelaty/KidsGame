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
| `test/features/` | Controller and rules logic per feature: `SessionController` phases/limits/breaks, `SettingsController` (PIN change/check, restore-defaults keeping the PIN), `ProgressController` neutral counting, `RewardsController` star/sticker awards, `GameAccess` (de)serialization, profile stage handling |
| `test/shared/` | The shared game framework: `ToddlerGame` hint countdown + escalation ladder, `resolveDrop` snapping, `StageConfig` values, Milo state transitions |
| `test/widgets/` | Widget tests: parent corner gate + PIN screen, dashboard sections reacting to controllers, reward overlay, child home phases (ready/resting) |
| `integration_test/` | On-device smoke: full bootstrap with real `SharedPreferences`, navigating home → map → a mini-game → completion → reward |

Every layer was built for testability — use these seams instead of mocking frameworks:

- `InMemoryStore` (`lib/core/persistence/local_store.dart`) replaces SharedPreferences.
- `NoopGameAudio` (`lib/core/audio/audio_manager.dart`) records every effect/instruction id it
  was asked to play — assert on `noop.effects` / `noop.instructions`.
- `AppServices.bootstrap(store: InMemoryStore(), enableAutoTick: false, initAudio: false)` gives
  a fully wired app without platform channels, real timers, or audio players.
- `SessionController` takes an injectable `clock` and, with `enableAutoTick: false`, is driven by
  calling `tick()` manually — no fake `Timer`s needed.

## Testing a new mini-game

**1. Pure rules first (no widgets, no Flame mounting needed for most logic).** Construct the game
with a hand-built `GameContext`:

```dart
final audio = NoopGameAudio();
var hints = 0;
var completed = false;

final game = MyNewGame(GameContext(
  stageConfig: StageConfig.explorer,     // test each stage's values explicitly
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

**2. Stage behaviour.** Run the same rules against `StageConfig.explorer` / `helper` /
`littleThinker` and assert counts/sizes/hint delays come from the config — a game that
hard-codes them is a bug (see ARCHITECTURE.md, "Stage system").

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

`ChildHomeScreen`, `SleepyScreen`, `RewardOverlay`, and `MiniGameScreen` all contain Milo — this
rule applies to every test that shows them.

**5. Checklist for the new game's test file(s)**

- [ ] Completes via its intended interactions; `onCompleted` fired once
- [ ] Hint appears after `stage.hintDelay` idle and repeats; reported via `onHintShown`
- [ ] Wrong-attempt ladder in order, no negative feedback beyond the soft bounce
- [ ] Auto-assist guarantees the child can never be stuck
- [ ] All three `StageConfig`s change counts/sizes as designed
- [ ] Voice ids used exist in `VoiceInstruction` (and files regenerated via `tool/gen_audio.py`)
- [ ] Registered in `GameRegistry` (title resolves for EN + AR, skills listed, world map shows it)
- [ ] Stickers exist in `StickerCatalog` so the reward flow can award them

## Manual testing

Automated tests cannot judge whether a two-year-old understands the game. Before any release —
and after any change to interaction, audio, or pacing — run the manual pass in
[docs/TODDLER_USABILITY_CHECKLIST.md](docs/TODDLER_USABILITY_CHECKLIST.md) on a real device.
