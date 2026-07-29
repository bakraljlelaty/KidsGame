import '../../core/persistence/json_document.dart';
import '../../core/persistence/local_store.dart';
import '../../shared/models/development_stage.dart';

/// Approximate age group only — never an exact birth date.
enum AgeGroup {
  aroundTwo('around_two'),
  aroundThree('around_three');

  const AgeGroup(this.storageKey);
  final String storageKey;

  static AgeGroup fromStorageKey(String? key) =>
      key == AgeGroup.aroundThree.storageKey
          ? AgeGroup.aroundThree
          : AgeGroup.aroundTwo;
}

/// Minimal child profile: nickname, approximate age group, avatar, language,
/// stage. Deliberately excludes real names, birth dates, photos, or any
/// other personal data.
class ChildProfile {
  const ChildProfile({
    this.nickname = '',
    this.ageGroup = AgeGroup.aroundTwo,
    this.avatarId = 'star',
    this.languageCode = 'en',
    this.stage = DevelopmentStage.explorer,
    this.autoStageProgression = true,
  });

  final String nickname;
  final AgeGroup ageGroup;
  final String avatarId;
  final String languageCode;
  final DevelopmentStage stage;
  final bool autoStageProgression;

  ChildProfile copyWith({
    String? nickname,
    AgeGroup? ageGroup,
    String? avatarId,
    String? languageCode,
    DevelopmentStage? stage,
    bool? autoStageProgression,
  }) =>
      ChildProfile(
        nickname: nickname ?? this.nickname,
        ageGroup: ageGroup ?? this.ageGroup,
        avatarId: avatarId ?? this.avatarId,
        languageCode: languageCode ?? this.languageCode,
        stage: stage ?? this.stage,
        autoStageProgression: autoStageProgression ?? this.autoStageProgression,
      );

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'ageGroup': ageGroup.storageKey,
        'avatarId': avatarId,
        'languageCode': languageCode,
        'stage': stage.storageKey,
        'autoStageProgression': autoStageProgression,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        nickname: json['nickname'] as String? ?? '',
        ageGroup: AgeGroup.fromStorageKey(json['ageGroup'] as String?),
        avatarId: json['avatarId'] as String? ?? 'star',
        languageCode: json['languageCode'] as String? ?? 'en',
        stage: DevelopmentStage.fromStorageKey(json['stage'] as String?),
        autoStageProgression: json['autoStageProgression'] as bool? ?? true,
      );
}

class ProfileRepository {
  ProfileRepository(LocalStore store)
      : _doc = JsonDocument<ChildProfile>(
          store: store,
          storeKey: 'profile',
          decode: ChildProfile.fromJson,
          encode: (p) => p.toJson(),
          fallback: () => const ChildProfile(),
        );

  final JsonDocument<ChildProfile> _doc;

  Future<ChildProfile> load() => _doc.load();
  Future<void> save(ChildProfile profile) => _doc.save(profile);
  Future<void> clear() => _doc.clear();
}
