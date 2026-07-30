import '../../core/persistence/json_document.dart';
import '../../core/persistence/local_store.dart';
import '../../shared/models/age_band.dart';
import '../../shared/models/development_stage.dart';

/// Minimal child profile: nickname, age band, avatar, language. Deliberately
/// excludes real names, birth dates, photos, or any other personal data.
///
/// v2: the academy's [AgeBand] replaces the v1 age group + development
/// stage; [stage] remains as a derived value for the six bespoke
/// mini-games and old call sites.
class ChildProfile {
  const ChildProfile({
    this.nickname = '',
    this.band = AgeBand.twoToThree,
    this.avatarId = 'star',
    this.languageCode = 'en',
    this.autoStageProgression = true,
  });

  final String nickname;
  final AgeBand band;
  final String avatarId;
  final String languageCode;

  /// Gentle automatic band progression (never speed-based).
  final bool autoStageProgression;

  /// v1 compatibility: the stage the bespoke mini-games play at.
  DevelopmentStage get stage => band.legacyStage;

  ChildProfile copyWith({
    String? nickname,
    AgeBand? band,
    String? avatarId,
    String? languageCode,
    bool? autoStageProgression,
  }) =>
      ChildProfile(
        nickname: nickname ?? this.nickname,
        band: band ?? this.band,
        avatarId: avatarId ?? this.avatarId,
        languageCode: languageCode ?? this.languageCode,
        autoStageProgression: autoStageProgression ?? this.autoStageProgression,
      );

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'band': band.storageKey,
        'avatarId': avatarId,
        'languageCode': languageCode,
        'autoStageProgression': autoStageProgression,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    // Defensive in-model migration: v1 documents carried 'stage' and
    // 'ageGroup' instead of 'band' (formally handled by DataMigrator, but a
    // fallback here keeps any straggler document safe).
    AgeBand band;
    final bandKey = json['band'] as String?;
    if (bandKey != null) {
      band = AgeBand.fromStorageKey(bandKey);
    } else if (json['stage'] != null) {
      band = AgeBand.fromLegacyStage(
        DevelopmentStage.fromStorageKey(json['stage'] as String?),
      );
    } else {
      band = AgeBand.twoToThree;
    }
    return ChildProfile(
      nickname: json['nickname'] as String? ?? '',
      band: band,
      avatarId: json['avatarId'] as String? ?? 'star',
      languageCode: json['languageCode'] as String? ?? 'en',
      autoStageProgression: json['autoStageProgression'] as bool? ?? true,
    );
  }
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
