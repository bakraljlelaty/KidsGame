import '../../core/persistence/json_document.dart';
import '../../core/persistence/local_store.dart';

/// Parent-chosen session timing rules.
class SessionConfig {
  const SessionConfig({
    this.sessionMinutes = 10,
    this.dailyLimitMinutes = 30,
    this.breakMinutes = 30,
  });

  /// 5, 10, 15, 20, or null for "no automatic timer".
  final int? sessionMinutes;

  /// Total minutes allowed per calendar day; null = no daily limit.
  final int? dailyLimitMinutes;

  /// Minutes of rest before a new session may start on its own.
  final int breakMinutes;

  SessionConfig copyWith({
    int? Function()? sessionMinutes,
    int? Function()? dailyLimitMinutes,
    int? breakMinutes,
  }) =>
      SessionConfig(
        sessionMinutes:
            sessionMinutes != null ? sessionMinutes() : this.sessionMinutes,
        dailyLimitMinutes: dailyLimitMinutes != null
            ? dailyLimitMinutes()
            : this.dailyLimitMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
      );

  Map<String, dynamic> toJson() => {
        'sessionMinutes': sessionMinutes,
        'dailyLimitMinutes': dailyLimitMinutes,
        'breakMinutes': breakMinutes,
      };

  factory SessionConfig.fromJson(Map<String, dynamic> json) => SessionConfig(
        sessionMinutes: json['sessionMinutes'] as int?,
        dailyLimitMinutes: json['dailyLimitMinutes'] as int?,
        breakMinutes: json['breakMinutes'] as int? ?? 30,
      );
}

/// Persisted usage state so limits survive app restarts.
class SessionUsage {
  const SessionUsage({
    this.dayKey = '',
    this.playedTodayMs = 0,
    this.lastSessionEndEpochMs,
    this.parentUnlockEpochMs,
  });

  /// "yyyy-mm-dd" of the day [playedTodayMs] belongs to.
  final String dayKey;
  final int playedTodayMs;
  final int? lastSessionEndEpochMs;

  /// Set when a parent taps "allow another session now".
  final int? parentUnlockEpochMs;

  SessionUsage copyWith({
    String? dayKey,
    int? playedTodayMs,
    int? Function()? lastSessionEndEpochMs,
    int? Function()? parentUnlockEpochMs,
  }) =>
      SessionUsage(
        dayKey: dayKey ?? this.dayKey,
        playedTodayMs: playedTodayMs ?? this.playedTodayMs,
        lastSessionEndEpochMs: lastSessionEndEpochMs != null
            ? lastSessionEndEpochMs()
            : this.lastSessionEndEpochMs,
        parentUnlockEpochMs: parentUnlockEpochMs != null
            ? parentUnlockEpochMs()
            : this.parentUnlockEpochMs,
      );

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'playedTodayMs': playedTodayMs,
        'lastSessionEndEpochMs': lastSessionEndEpochMs,
        'parentUnlockEpochMs': parentUnlockEpochMs,
      };

  factory SessionUsage.fromJson(Map<String, dynamic> json) => SessionUsage(
        dayKey: json['dayKey'] as String? ?? '',
        playedTodayMs: json['playedTodayMs'] as int? ?? 0,
        lastSessionEndEpochMs: json['lastSessionEndEpochMs'] as int?,
        parentUnlockEpochMs: json['parentUnlockEpochMs'] as int?,
      );
}

class SessionRepository {
  SessionRepository(LocalStore store)
      : _configDoc = JsonDocument<SessionConfig>(
          store: store,
          storeKey: 'session_config',
          decode: SessionConfig.fromJson,
          encode: (c) => c.toJson(),
          fallback: () => const SessionConfig(),
        ),
        _usageDoc = JsonDocument<SessionUsage>(
          store: store,
          storeKey: 'session_usage',
          decode: SessionUsage.fromJson,
          encode: (u) => u.toJson(),
          fallback: () => const SessionUsage(),
        );

  final JsonDocument<SessionConfig> _configDoc;
  final JsonDocument<SessionUsage> _usageDoc;

  Future<SessionConfig> loadConfig() => _configDoc.load();
  Future<void> saveConfig(SessionConfig config) => _configDoc.save(config);
  Future<SessionUsage> loadUsage() => _usageDoc.load();
  Future<void> saveUsage(SessionUsage usage) => _usageDoc.save(usage);
  Future<void> clear() async {
    await _configDoc.clear();
    await _usageDoc.clear();
  }
}
