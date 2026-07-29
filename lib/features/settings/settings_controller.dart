import 'package:flutter/foundation.dart';

import 'app_settings.dart';

/// Owns [AppSettings]; parent screens mutate through this controller and the
/// rest of the app (audio, theme, games) listens.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  Future<void> init() async {
    _settings = await _repository.load();
    notifyListeners();
  }

  Future<void> _update(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _repository.save(next);
  }

  Future<void> setMusicEnabled(bool value) =>
      _update(_settings.copyWith(musicEnabled: value));

  Future<void> setSoundEffectsEnabled(bool value) =>
      _update(_settings.copyWith(soundEffectsEnabled: value));

  Future<void> setVoiceEnabled(bool value) =>
      _update(_settings.copyWith(voiceEnabled: value));

  Future<void> setLanguage(String code) =>
      _update(_settings.copyWith(languageCode: code));

  Future<void> setReducedMotion(bool value) =>
      _update(_settings.copyWith(reducedMotion: value));

  Future<void> setHighContrast(bool value) =>
      _update(_settings.copyWith(highContrast: value));

  Future<void> setHapticsEnabled(bool value) =>
      _update(_settings.copyWith(hapticsEnabled: value));

  Future<void> setLeftHanded(bool value) =>
      _update(_settings.copyWith(leftHanded: value));

  Future<void> setParentPin(String pin) =>
      _update(_settings.copyWith(parentPin: pin));

  bool checkPin(String pin) => pin == _settings.parentPin;

  Future<void> restoreDefaults() => _update(_settings.restoredToDefaults());

  /// Called after "delete all data" wiped the store.
  Future<void> reloadFromStore() async {
    _settings = await _repository.load();
    notifyListeners();
  }
}
