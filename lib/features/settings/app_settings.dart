import '../../config/app_config.dart';
import '../../core/persistence/json_document.dart';
import '../../core/persistence/local_store.dart';

/// Parent-configurable application settings, stored locally.
class AppSettings {
  const AppSettings({
    this.musicEnabled = true,
    this.soundEffectsEnabled = true,
    this.voiceEnabled = true,
    this.languageCode = 'en',
    this.reducedMotion = false,
    this.highContrast = false,
    this.hapticsEnabled = true,
    this.leftHanded = false,
    this.parentPin = AppConfig.defaultParentPin,
  });

  final bool musicEnabled;
  final bool soundEffectsEnabled;
  final bool voiceEnabled;
  final String languageCode;
  final bool reducedMotion;
  final bool highContrast;
  final bool hapticsEnabled;
  final bool leftHanded;
  final String parentPin;

  bool get usesDefaultPin => parentPin == AppConfig.defaultParentPin;

  AppSettings copyWith({
    bool? musicEnabled,
    bool? soundEffectsEnabled,
    bool? voiceEnabled,
    String? languageCode,
    bool? reducedMotion,
    bool? highContrast,
    bool? hapticsEnabled,
    bool? leftHanded,
    String? parentPin,
  }) =>
      AppSettings(
        musicEnabled: musicEnabled ?? this.musicEnabled,
        soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
        voiceEnabled: voiceEnabled ?? this.voiceEnabled,
        languageCode: languageCode ?? this.languageCode,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        highContrast: highContrast ?? this.highContrast,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        leftHanded: leftHanded ?? this.leftHanded,
        parentPin: parentPin ?? this.parentPin,
      );

  /// Defaults, but the PIN survives so restoring settings never silently
  /// reverts the gate to the well-known development PIN.
  AppSettings restoredToDefaults() => AppSettings(parentPin: parentPin);

  Map<String, dynamic> toJson() => {
        'musicEnabled': musicEnabled,
        'soundEffectsEnabled': soundEffectsEnabled,
        'voiceEnabled': voiceEnabled,
        'languageCode': languageCode,
        'reducedMotion': reducedMotion,
        'highContrast': highContrast,
        'hapticsEnabled': hapticsEnabled,
        'leftHanded': leftHanded,
        'parentPin': parentPin,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        musicEnabled: json['musicEnabled'] as bool? ?? true,
        soundEffectsEnabled: json['soundEffectsEnabled'] as bool? ?? true,
        voiceEnabled: json['voiceEnabled'] as bool? ?? true,
        languageCode: json['languageCode'] as String? ?? 'en',
        reducedMotion: json['reducedMotion'] as bool? ?? false,
        highContrast: json['highContrast'] as bool? ?? false,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        leftHanded: json['leftHanded'] as bool? ?? false,
        parentPin: json['parentPin'] as String? ?? AppConfig.defaultParentPin,
      );
}

class SettingsRepository {
  SettingsRepository(LocalStore store)
      : _doc = JsonDocument<AppSettings>(
          store: store,
          storeKey: 'settings',
          decode: AppSettings.fromJson,
          encode: (s) => s.toJson(),
          fallback: () => const AppSettings(),
        );

  final JsonDocument<AppSettings> _doc;

  Future<AppSettings> load() => _doc.load();
  Future<void> save(AppSettings settings) => _doc.save(settings);
  Future<void> clear() => _doc.clear();
}
