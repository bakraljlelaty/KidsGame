import '../../core/persistence/json_document.dart';
import '../../core/persistence/local_store.dart';
import '../../shared/models/game_id.dart';
import '../../shared/models/subject.dart';

/// Stars, earned stickers and decoration progress. All cosmetic, nothing
/// purchasable, no scores or rankings.
class RewardData {
  RewardData({
    Map<GameId, int>? stars,
    Map<Subject, int>? subjectStars,
    Set<String>? earnedStickerIds,
    this.decorationPoints = 0,
  })  : stars = stars ?? {},
        subjectStars = subjectStars ?? {},
        earnedStickerIds = earnedStickerIds ?? {};

  /// Completion stars per game (capped for display; no leaderboard).
  final Map<GameId, int> stars;

  /// Stars earned in academy activities, per concept area (v2).
  final Map<Subject, int> subjectStars;

  /// Sticker ids from StickerCatalog the child has earned.
  final Set<String> earnedStickerIds;

  /// Slowly growing decoration progress for the world map (flowers, lights).
  final int decorationPoints;

  int starsFor(GameId id) => stars[id] ?? 0;

  int starsForSubject(Subject subject) => subjectStars[subject] ?? 0;

  int get totalStars =>
      stars.values.fold(0, (sum, s) => sum + s) +
      subjectStars.values.fold(0, (sum, s) => sum + s);

  RewardData copyWith({
    Map<GameId, int>? stars,
    Map<Subject, int>? subjectStars,
    Set<String>? earnedStickerIds,
    int? decorationPoints,
  }) =>
      RewardData(
        stars: stars ?? this.stars,
        subjectStars: subjectStars ?? this.subjectStars,
        earnedStickerIds: earnedStickerIds ?? this.earnedStickerIds,
        decorationPoints: decorationPoints ?? this.decorationPoints,
      );

  Map<String, dynamic> toJson() => {
        'stars': {
          for (final e in stars.entries) e.key.storageKey: e.value,
        },
        'subjectStars': {
          for (final e in subjectStars.entries) e.key.storageKey: e.value,
        },
        'earnedStickerIds': earnedStickerIds.toList(),
        'decorationPoints': decorationPoints,
      };

  factory RewardData.fromJson(Map<String, dynamic> json) {
    final starsRaw = (json['stars'] as Map?)?.cast<String, dynamic>() ?? {};
    final subjectStarsRaw =
        (json['subjectStars'] as Map?)?.cast<String, dynamic>() ?? {};
    return RewardData(
      stars: {
        for (final e in starsRaw.entries)
          if (GameId.fromStorageKey(e.key) != null)
            GameId.fromStorageKey(e.key)!: e.value as int? ?? 0,
      },
      subjectStars: {
        for (final e in subjectStarsRaw.entries)
          if (Subject.fromStorageKey(e.key) != null)
            Subject.fromStorageKey(e.key)!: e.value as int? ?? 0,
      },
      earnedStickerIds:
          ((json['earnedStickerIds'] as List?)?.cast<String>() ?? []).toSet(),
      decorationPoints: json['decorationPoints'] as int? ?? 0,
    );
  }
}

class RewardRepository {
  RewardRepository(LocalStore store)
      : _doc = JsonDocument<RewardData>(
          store: store,
          storeKey: 'rewards',
          decode: RewardData.fromJson,
          encode: (r) => r.toJson(),
          fallback: RewardData.new,
        );

  final JsonDocument<RewardData> _doc;

  Future<RewardData> load() => _doc.load();
  Future<void> save(RewardData data) => _doc.save(data);
  Future<void> clear() => _doc.clear();
}
