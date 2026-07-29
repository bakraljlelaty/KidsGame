import 'package:flutter/foundation.dart';

import '../../shared/models/game_id.dart';
import '../../shared/models/skill.dart';
import '../profiles/profile_controller.dart';
import 'progress_data.dart';

/// Records neutral play statistics and drives gentle automatic stage
/// progression.
class ProgressController extends ChangeNotifier {
  ProgressController(this._repository, this._profile);

  /// Relaxed (hint-free) completions needed before the stage moves up when
  /// automatic progression is on. Deliberately spread over multiple
  /// sessions; speed is never considered.
  static const int advanceAfterRelaxedCompletions = 6;

  final ProgressRepository _repository;
  final ProfileController _profile;

  ProgressData _data = ProgressData();
  ProgressData get data => _data;

  Future<void> init() async {
    _data = await _repository.load();
    notifyListeners();
  }

  Future<void> _update(ProgressData next) async {
    _data = next;
    notifyListeners();
    await _repository.save(next);
  }

  Future<void> recordGameStarted(GameId id) async {
    final game = _data.of(id);
    await _update(
      _data.copyWith(
        games: {..._data.games, id: game.copyWith(attempts: game.attempts + 1)},
      ),
    );
  }

  Future<void> recordHintShown(GameId id) async {
    final game = _data.of(id);
    await _update(
      _data.copyWith(
        games: {
          ..._data.games,
          id: game.copyWith(hintsShown: game.hintsShown + 1),
        },
      ),
    );
  }

  Future<void> recordCompletion(
    GameId id, {
    required List<Skill> skills,
    required bool usedHints,
    required Duration playTime,
  }) async {
    final game = _data.of(id);
    final updatedGame = game.copyWith(
      completions: game.completions + 1,
      completionsWithoutHints:
          game.completionsWithoutHints + (usedHints ? 0 : 1),
      playMs: game.playMs + playTime.inMilliseconds,
    );
    final updatedSkills = {..._data.skillPlays};
    for (final skill in skills) {
      updatedSkills[skill] = (updatedSkills[skill] ?? 0) + 1;
    }
    var streak = _data.relaxedCompletionStreak + (usedHints ? 0 : 1);

    await _update(
      _data.copyWith(
        games: {..._data.games, id: updatedGame},
        skillPlays: updatedSkills,
        relaxedCompletionStreak: streak,
      ),
    );

    await _maybeAdvanceStage(streak);
  }

  Future<void> _maybeAdvanceStage(int streak) async {
    final profile = _profile.profile;
    if (!profile.autoStageProgression) return;
    if (streak < advanceAfterRelaxedCompletions) return;
    final next = profile.stage.next;
    if (next == null) return;
    await _profile.setStage(next);
    await _update(_data.copyWith(relaxedCompletionStreak: 0));
  }

  Future<void> reset() async {
    await _update(ProgressData());
  }

  Future<void> reloadFromStore() async {
    _data = await _repository.load();
    notifyListeners();
  }
}
