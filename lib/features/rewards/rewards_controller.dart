import 'package:flutter/foundation.dart';

import '../../shared/models/game_id.dart';
import '../../shared/models/subject.dart';
import 'reward_data.dart';
import 'sticker_catalog.dart';

/// What one completed activity earned. Always positive, never a score.
class CompletionReward {
  const CompletionReward({
    required this.totalStarsForGame,
    required this.sticker,
    required this.isNewSticker,
  });

  final int totalStarsForGame;

  /// The sticker celebrated in the reward overlay (a newly earned one when
  /// available, otherwise a favourite already-earned one).
  final StickerDef? sticker;
  final bool isNewSticker;
}

class RewardsController extends ChangeNotifier {
  RewardsController(this._repository);

  final RewardRepository _repository;

  RewardData _data = RewardData();
  RewardData get data => _data;

  Future<void> init() async {
    _data = await _repository.load();
    notifyListeners();
  }

  Future<void> _update(RewardData next) async {
    _data = next;
    notifyListeners();
    await _repository.save(next);
  }

  /// Awards one star, the next unearned sticker of the game (participation
  /// based — completing is enough), and a decoration point.
  Future<CompletionReward> awardCompletion(GameId id) async {
    final gameStickers = StickerCatalog.forGame(id);
    StickerDef? newSticker;
    for (final sticker in gameStickers) {
      if (!_data.earnedStickerIds.contains(sticker.id)) {
        newSticker = sticker;
        break;
      }
    }

    final updated = _data.copyWith(
      stars: {..._data.stars, id: _data.starsFor(id) + 1},
      earnedStickerIds: {
        ..._data.earnedStickerIds,
        if (newSticker != null) newSticker.id,
      },
      decorationPoints: _data.decorationPoints + 1,
    );
    await _update(updated);

    return CompletionReward(
      totalStarsForGame: updated.starsFor(id),
      sticker:
          newSticker ?? (gameStickers.isNotEmpty ? gameStickers.first : null),
      isNewSticker: newSticker != null,
    );
  }

  /// Awards a star for an academy activity; a sticker joins the
  /// celebration when a path unit was just completed (participation-based,
  /// never performance-based).
  Future<CompletionReward> awardActivityCompletion(
    Subject subject, {
    bool unitCompleted = false,
  }) async {
    StickerDef? newSticker;
    if (unitCompleted) {
      for (final sticker in StickerCatalog.all) {
        if (!_data.earnedStickerIds.contains(sticker.id)) {
          newSticker = sticker;
          break;
        }
      }
    }
    final updated = _data.copyWith(
      subjectStars: {
        ..._data.subjectStars,
        subject: _data.starsForSubject(subject) + 1,
      },
      earnedStickerIds: {
        ..._data.earnedStickerIds,
        if (newSticker != null) newSticker.id,
      },
      decorationPoints: _data.decorationPoints + 1,
    );
    await _update(updated);
    return CompletionReward(
      totalStarsForGame: updated.starsForSubject(subject),
      sticker: newSticker,
      isNewSticker: newSticker != null,
    );
  }

  List<StickerDef> get earnedStickers => [
        for (final sticker in StickerCatalog.all)
          if (_data.earnedStickerIds.contains(sticker.id)) sticker,
      ];

  Future<void> reset() => _update(RewardData());

  Future<void> reloadFromStore() async {
    _data = await _repository.load();
    notifyListeners();
  }
}
