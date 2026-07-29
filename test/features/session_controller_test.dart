import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/session_control/session_controller.dart';
import 'package:little_wonder_world/features/session_control/session_data.dart';

/// Deterministic harness: a mutable clock plus manual ticks (auto tick off).
class SessionHarness {
  SessionHarness({InMemoryStore? store})
      : store = store ?? InMemoryStore(),
        now = DateTime(2026, 1, 5, 10, 0, 0) {
    controller = SessionController(
      SessionRepository(this.store),
      clock: () => now,
      enableAutoTick: false,
    );
    controller.onWarning = () => warnings++;
    controller.onTimeUp = () => timeUps++;
  }

  final InMemoryStore store;
  DateTime now;
  late final SessionController controller;
  int warnings = 0;
  int timeUps = 0;

  /// Simulates [seconds] of active play: the clock advances 1s per tick,
  /// matching the app's periodic timer (gaps > 5s would be capped to 1s).
  void playSeconds(int seconds) {
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      controller.tick();
    }
  }

  void advanceClock(Duration duration) {
    now = now.add(duration);
  }
}

void main() {
  test('init leaves a fresh controller in the ready phase', () async {
    final h = SessionHarness();
    await h.controller.init();
    expect(h.controller.phase, SessionPhase.ready);
    expect(h.controller.canStartSession, isTrue);
    expect(h.controller.playedToday, Duration.zero);
  });

  test('startSession returns true and enters running', () async {
    final h = SessionHarness();
    await h.controller.init();
    expect(h.controller.startSession(), isTrue);
    expect(h.controller.phase, SessionPhase.running);
  });

  test(
      'ticking to the limit fires the warning once at <= 1 minute remaining '
      'and time-up at zero, entering windDown', () async {
    final h = SessionHarness();
    await h.controller.init();
    await h.controller.updateConfig(const SessionConfig(
      sessionMinutes: 2,
      dailyLimitMinutes: 30,
      breakMinutes: 10,
    ));
    h.controller.startSession();

    // 59s in: 61s remaining, no warning yet.
    h.playSeconds(59);
    expect(h.warnings, 0);
    expect(h.timeUps, 0);

    // 60s in: exactly 1 minute remaining -> warning fires.
    h.playSeconds(1);
    expect(h.warnings, 1);
    expect(h.timeUps, 0);
    expect(h.controller.phase, SessionPhase.running);

    // Keep playing to 119s: warning must not repeat.
    h.playSeconds(59);
    expect(h.warnings, 1);
    expect(h.timeUps, 0);

    // 120s: remaining hits zero -> wind down begins.
    h.playSeconds(1);
    expect(h.warnings, 1);
    expect(h.timeUps, 1);
    expect(h.controller.phase, SessionPhase.windDown);

    // Further ticks while winding down change nothing.
    h.playSeconds(5);
    expect(h.timeUps, 1);
    expect(h.controller.phase, SessionPhase.windDown);
  });

  test('finishWindDown persists usage and blocks until the break passes',
      () async {
    final h = SessionHarness();
    await h.controller.init();
    await h.controller.updateConfig(const SessionConfig(
      sessionMinutes: 2,
      dailyLimitMinutes: 30,
      breakMinutes: 10,
    ));
    h.controller.startSession();
    h.playSeconds(120);
    expect(h.controller.phase, SessionPhase.windDown);

    await h.controller.finishWindDown();

    // Usage was persisted to the store.
    final persisted = await SessionRepository(h.store).loadUsage();
    expect(persisted.playedTodayMs, 120 * 1000);
    expect(persisted.lastSessionEndEpochMs, h.now.millisecondsSinceEpoch);

    // The break has not passed yet: blocked, no new session.
    expect(h.controller.phase, SessionPhase.blocked);
    expect(h.controller.canStartSession, isFalse);
    expect(h.controller.startSession(), isFalse);

    // Not yet: one minute short of the break.
    h.advanceClock(const Duration(minutes: 9));
    expect(h.controller.canStartSession, isFalse);

    // Past the break: a new session may start.
    h.advanceClock(const Duration(minutes: 1, seconds: 1));
    expect(h.controller.canStartSession, isTrue);
    expect(h.controller.startSession(), isTrue);
    expect(h.controller.phase, SessionPhase.running);
  });

  test(
      'an exhausted daily limit keeps canStartSession false even after the '
      'break, and a parent unlock opens it immediately', () async {
    final h = SessionHarness();
    await h.controller.init();
    await h.controller.updateConfig(const SessionConfig(
      sessionMinutes: 1,
      dailyLimitMinutes: 2,
      breakMinutes: 1,
    ));

    // Session 1: one minute of play.
    expect(h.controller.startSession(), isTrue);
    h.playSeconds(60);
    expect(h.controller.phase, SessionPhase.windDown);
    await h.controller.finishWindDown();
    expect(h.controller.playedToday, const Duration(minutes: 1));

    // After the break the child may play again (daily limit not hit yet).
    h.advanceClock(const Duration(minutes: 2));
    expect(h.controller.canStartSession, isTrue);

    // Session 2 exhausts the 2-minute daily limit.
    expect(h.controller.startSession(), isTrue);
    h.playSeconds(60);
    expect(h.controller.phase, SessionPhase.windDown);
    await h.controller.finishWindDown();
    expect(h.controller.playedToday, const Duration(minutes: 2));
    expect(h.controller.canStartSession, isFalse);

    // Waiting far past the break does not help: the day is used up.
    h.advanceClock(const Duration(hours: 1));
    expect(h.controller.canStartSession, isFalse);
    expect(h.controller.startSession(), isFalse);
    expect(h.controller.phase, SessionPhase.blocked);

    // A parent unlock opens one more session immediately.
    await h.controller.parentAllowExtraSession();
    expect(h.controller.canStartSession, isTrue);
    expect(h.controller.phase, SessionPhase.ready);
    expect(h.controller.startSession(), isTrue);
  });

  test('day rollover resets playedToday and unblocks the next morning',
      () async {
    final h = SessionHarness();
    await h.controller.init();
    await h.controller.updateConfig(const SessionConfig(
      sessionMinutes: 2,
      dailyLimitMinutes: 2,
      breakMinutes: 1,
    ));

    // Use up the whole daily allowance.
    h.controller.startSession();
    h.playSeconds(120);
    await h.controller.finishWindDown();
    expect(h.controller.playedToday, const Duration(minutes: 2));
    expect(h.controller.canStartSession, isFalse);

    // Next day, app comes back: usage rolls over.
    h.now = DateTime(2026, 1, 6, 9, 0, 0);
    await h.controller.reloadFromStore();
    expect(h.controller.playedToday, Duration.zero);
    expect(h.controller.canStartSession, isTrue);
    expect(h.controller.phase, SessionPhase.ready);
  });

  test('a "no timer" config never winds down', () async {
    final h = SessionHarness();
    await h.controller.init();
    await h.controller.updateConfig(const SessionConfig(
      sessionMinutes: null,
      dailyLimitMinutes: null,
      breakMinutes: 30,
    ));

    h.controller.startSession();
    h.playSeconds(300); // 5 minutes of play, no limit anywhere.

    expect(h.controller.phase, SessionPhase.running);
    expect(h.warnings, 0);
    expect(h.timeUps, 0);
    expect(h.controller.remaining, isNull);
    expect(h.controller.playedToday, const Duration(minutes: 5));
  });

  test('usage persists into a new controller on the same store', () async {
    final h = SessionHarness();
    await h.controller.init();
    await h.controller.updateConfig(const SessionConfig(
      sessionMinutes: 2,
      dailyLimitMinutes: 30,
      breakMinutes: 10,
    ));
    h.controller.startSession();
    h.playSeconds(120);
    await h.controller.finishWindDown();
    final endedAt = h.now;

    // "App restart": fresh controller over the same store and clock.
    final revived = SessionController(
      SessionRepository(h.store),
      clock: () => h.now,
      enableAutoTick: false,
    );
    await revived.init();

    expect(revived.playedToday, const Duration(minutes: 2));
    expect(revived.usage.lastSessionEndEpochMs, endedAt.millisecondsSinceEpoch);
    expect(revived.config.sessionMinutes, 2);
    expect(revived.canStartSession, isFalse); // still inside the break
    expect(revived.phase, SessionPhase.blocked);
  });
}
