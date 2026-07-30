/// Central product configuration.
///
/// "Little Wonder World" is a working title. Change [appName] (and the
/// Android launcher label in `android/app/src/main/AndroidManifest.xml`)
/// when the final name is chosen. See README "Changing the application name".
class AppConfig {
  AppConfig._();

  /// Product display name (working title).
  static const String appName = 'Little Wonder World';

  /// Default parent PIN for development builds. Parents are prompted to
  /// change it from the dashboard; the current PIN is stored locally.
  static const String defaultParentPin = '2468';

  /// How long both top corners must be held to open the parent gate.
  static const Duration parentGateHold = Duration(seconds: 3);

  /// Minimum toddler touch target, in logical pixels. Deliberately much
  /// larger than the standard 48dp mobile minimum.
  static const double minTouchTarget = 88;

  /// Reminder sound plays this long before a session ends.
  static const Duration sessionEndWarning = Duration(minutes: 1);

  /// Wrong-attempt escalation thresholds (shared by all mini-games).
  static const int replayInstructionAfterAttempts = 2;
  static const int highlightTargetAfterAttempts = 3;
  static const int autoAssistAfterAttempts = 4;

  /// Highest level of every mini-game. Levels ramp gently within the
  /// child's development stage; completing a game advances its level.
  static const int maxGameLevel = 5;

  /// Current local data schema version (see DataMigrator).
  /// v2: academy age bands replace the v1 age group + development stage.
  static const int dataSchemaVersion = 2;
}
