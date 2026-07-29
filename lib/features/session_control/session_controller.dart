import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';
import 'session_data.dart';

/// Where the child currently is in the play-time cycle.
enum SessionPhase {
  /// A session may start (play button available).
  ready,

  /// The child is playing inside an active session.
  running,

  /// Time is up, but the child may finish the activity they are in.
  windDown,

  /// The session just ended; the app shows sleepy Milo, then [blocked].
  sleepy,

  /// No new session until the break passes, a new day starts, or a parent
  /// allows one.
  blocked,
}

/// Session timing engine.
///
/// Pure logic with an injectable [clock] and manual [tick] so unit tests can
/// drive time; the app attaches a periodic timer via [start]/[stop] wiring
/// in AppServices.
class SessionController extends ChangeNotifier {
  SessionController(
    this._repository, {
    DateTime Function()? clock,
    this.enableAutoTick = true,
  }) : _clock = clock ?? DateTime.now;

  final SessionRepository _repository;
  final DateTime Function() _clock;

  /// Disabled in tests so [tick] can be called manually.
  final bool enableAutoTick;

  SessionConfig _config = const SessionConfig();
  SessionConfig get config => _config;

  SessionUsage _usage = const SessionUsage();
  SessionUsage get usage => _usage;

  SessionPhase _phase = SessionPhase.ready;
  SessionPhase get phase => _phase;

  /// Uncommitted play time of the running session.
  Duration _elapsed = Duration.zero;

  /// Play time already persisted for this session (after app pauses).
  Duration _committedThisSession = Duration.zero;

  bool _warningFired = false;
  DateTime? _lastTickAt;
  Timer? _timer;

  /// Fired once, shortly before the session ends (plays the reminder sound).
  VoidCallback? onWarning;

  /// Fired when the timer elapses and wind-down begins.
  VoidCallback? onTimeUp;

  Future<void> init() async {
    _config = await _repository.loadConfig();
    _usage = await _repository.loadUsage();
    await _rollDayIfNeeded();
    _phase = canStartSession ? SessionPhase.ready : SessionPhase.blocked;
    notifyListeners();
  }

  String _dayKeyOf(DateTime time) =>
      '${time.year.toString().padLeft(4, '0')}-'
      '${time.month.toString().padLeft(2, '0')}-'
      '${time.day.toString().padLeft(2, '0')}';

  Future<void> _rollDayIfNeeded() async {
    final today = _dayKeyOf(_clock());
    if (_usage.dayKey != today) {
      _usage = SessionUsage(dayKey: today);
      await _repository.saveUsage(_usage);
    }
  }

  Duration get playedToday =>
      Duration(milliseconds: _usage.playedTodayMs) + _elapsed;

  /// Remaining time of the current session, or null when no limit applies.
  Duration? get remaining {
    Duration? sessionRemaining;
    final sessionMinutes = _config.sessionMinutes;
    if (sessionMinutes != null) {
      sessionRemaining = Duration(minutes: sessionMinutes) -
          _committedThisSession -
          _elapsed;
    }
    Duration? dailyRemaining;
    final dailyMinutes = _config.dailyLimitMinutes;
    if (dailyMinutes != null) {
      dailyRemaining = Duration(minutes: dailyMinutes) -
          Duration(milliseconds: _usage.playedTodayMs) -
          _elapsed;
    }
    if (sessionRemaining == null) return dailyRemaining;
    if (dailyRemaining == null) return sessionRemaining;
    return sessionRemaining < dailyRemaining
        ? sessionRemaining
        : dailyRemaining;
  }

  bool get canStartSession {
    final now = _clock();

    // A parent's explicit unlock always opens one more session.
    final unlock = _usage.parentUnlockEpochMs;
    final lastEnd = _usage.lastSessionEndEpochMs;
    if (unlock != null && (lastEnd == null || unlock > lastEnd)) return true;

    // Daily limit.
    final dailyMinutes = _config.dailyLimitMinutes;
    if (dailyMinutes != null &&
        _usage.playedTodayMs >= dailyMinutes * 60000) {
      return false;
    }

    // Break between sessions.
    if (lastEnd != null) {
      final sinceEnd =
          now.difference(DateTime.fromMillisecondsSinceEpoch(lastEnd));
      if (sinceEnd < Duration(minutes: _config.breakMinutes)) return false;
    }
    return true;
  }

  /// Starts a play session when allowed. Returns whether it started.
  bool startSession() {
    if (_phase == SessionPhase.running || _phase == SessionPhase.windDown) {
      return true;
    }
    if (!canStartSession) {
      _phase = SessionPhase.blocked;
      notifyListeners();
      return false;
    }
    _phase = SessionPhase.running;
    _elapsed = Duration.zero;
    _committedThisSession = Duration.zero;
    _warningFired = false;
    _lastTickAt = _clock();
    unawaited(_rollDayIfNeeded());
    if (enableAutoTick) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
    notifyListeners();
    return true;
  }

  /// Advances the session clock. Called every second while running.
  void tick() {
    if (_phase != SessionPhase.running) return;
    final now = _clock();
    final last = _lastTickAt ?? now;
    _lastTickAt = now;
    var delta = now.difference(last);
    // Ignore huge gaps (device slept); play time only counts active use.
    if (delta > const Duration(seconds: 5)) delta = const Duration(seconds: 1);
    _elapsed += delta;

    final left = remaining;
    if (left == null) return;

    if (!_warningFired && left <= AppConfig.sessionEndWarning) {
      _warningFired = true;
      onWarning?.call();
    }
    if (left <= Duration.zero) {
      _phase = SessionPhase.windDown;
      _timer?.cancel();
      onTimeUp?.call();
      notifyListeners();
    }
  }

  /// The current activity finished (or the child is on a menu screen) while
  /// winding down: end the session for real.
  Future<void> finishWindDown() async {
    if (_phase != SessionPhase.windDown) return;
    _phase = SessionPhase.sleepy;
    notifyListeners();
    await _commitSessionEnd();
  }

  /// Ends the session immediately (child pressed home, app closes, etc.).
  Future<void> endSessionNow() async {
    if (_phase != SessionPhase.running && _phase != SessionPhase.windDown) {
      return;
    }
    _phase = SessionPhase.sleepy;
    notifyListeners();
    await _commitSessionEnd();
  }

  Future<void> _commitSessionEnd() async {
    _timer?.cancel();
    final now = _clock();
    await _rollDayIfNeeded();
    _usage = _usage.copyWith(
      dayKey: _dayKeyOf(now),
      playedTodayMs: _usage.playedTodayMs + _elapsed.inMilliseconds,
      lastSessionEndEpochMs: () => now.millisecondsSinceEpoch,
      parentUnlockEpochMs: () => null,
    );
    _elapsed = Duration.zero;
    _committedThisSession = Duration.zero;
    await _repository.saveUsage(_usage);
    _phase = canStartSession ? SessionPhase.ready : SessionPhase.blocked;
    notifyListeners();
  }

  /// Leaves sleepy screen state without restarting a session.
  void acknowledgeSleepy() {
    if (_phase == SessionPhase.sleepy) {
      _phase = canStartSession ? SessionPhase.ready : SessionPhase.blocked;
      notifyListeners();
    }
  }

  /// Parent explicitly allows one more session right now.
  Future<void> parentAllowExtraSession() async {
    _usage = _usage.copyWith(
      parentUnlockEpochMs: () => _clock().millisecondsSinceEpoch,
    );
    await _repository.saveUsage(_usage);
    if (_phase == SessionPhase.blocked) _phase = SessionPhase.ready;
    notifyListeners();
  }

  Future<void> updateConfig(SessionConfig next) async {
    _config = next;
    await _repository.saveConfig(next);
    if (_phase == SessionPhase.blocked && canStartSession) {
      _phase = SessionPhase.ready;
    }
    notifyListeners();
  }

  /// App went to the background: persist progress so a kill loses nothing.
  Future<void> onAppPaused() async {
    _timer?.cancel();
    if (_phase == SessionPhase.running || _phase == SessionPhase.windDown) {
      _committedThisSession += _elapsed;
      _usage = _usage.copyWith(
        playedTodayMs: _usage.playedTodayMs + _elapsed.inMilliseconds,
      );
      _elapsed = Duration.zero;
      await _repository.saveUsage(_usage);
    }
  }

  void onAppResumed() {
    _lastTickAt = _clock();
    if (_phase == SessionPhase.running && enableAutoTick) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  Future<void> reloadFromStore() async {
    _timer?.cancel();
    _elapsed = Duration.zero;
    _committedThisSession = Duration.zero;
    await init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
