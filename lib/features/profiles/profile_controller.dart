import 'package:flutter/foundation.dart';

import '../../shared/models/age_band.dart';
import '../../shared/models/development_stage.dart';
import 'child_profile.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  ChildProfile _profile = const ChildProfile();
  ChildProfile get profile => _profile;

  BandConfig get bandConfig => BandConfig.of(_profile.band);

  /// v1 compatibility for the six bespoke mini-games.
  StageConfig get stageConfig => StageConfig.of(_profile.stage);

  Future<void> init() async {
    _profile = await _repository.load();
    notifyListeners();
  }

  Future<void> _update(ChildProfile next) async {
    _profile = next;
    notifyListeners();
    await _repository.save(next);
  }

  Future<void> setNickname(String value) =>
      _update(_profile.copyWith(nickname: value.trim()));

  Future<void> setBand(AgeBand value) =>
      _update(_profile.copyWith(band: value));

  /// v1 compatibility: setting a stage selects its default band.
  Future<void> setStage(DevelopmentStage stage) =>
      _update(_profile.copyWith(band: AgeBand.fromLegacyStage(stage)));

  Future<void> setAvatar(String avatarId) =>
      _update(_profile.copyWith(avatarId: avatarId));

  Future<void> setLanguage(String code) =>
      _update(_profile.copyWith(languageCode: code));

  Future<void> setAutoStageProgression(bool value) =>
      _update(_profile.copyWith(autoStageProgression: value));

  Future<void> reloadFromStore() async {
    _profile = await _repository.load();
    notifyListeners();
  }
}
