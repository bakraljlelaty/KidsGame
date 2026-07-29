import 'package:flutter/foundation.dart';

import '../../shared/models/development_stage.dart';
import 'child_profile.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  ChildProfile _profile = const ChildProfile();
  ChildProfile get profile => _profile;

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

  Future<void> setAgeGroup(AgeGroup value) =>
      _update(_profile.copyWith(ageGroup: value));

  Future<void> setAvatar(String avatarId) =>
      _update(_profile.copyWith(avatarId: avatarId));

  Future<void> setLanguage(String code) =>
      _update(_profile.copyWith(languageCode: code));

  Future<void> setStage(DevelopmentStage stage) =>
      _update(_profile.copyWith(stage: stage));

  Future<void> setAutoStageProgression(bool value) =>
      _update(_profile.copyWith(autoStageProgression: value));

  Future<void> reloadFromStore() async {
    _profile = await _repository.load();
    notifyListeners();
  }
}
