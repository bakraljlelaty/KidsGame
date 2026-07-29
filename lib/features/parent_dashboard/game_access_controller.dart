import 'package:flutter/foundation.dart';

import '../../shared/models/game_id.dart';
import '../progress/progress_data.dart';
import 'game_access.dart';

class GameAccessController extends ChangeNotifier {
  GameAccessController(this._repository);

  final GameAccessRepository _repository;

  GameAccess _access = GameAccess();
  GameAccess get access => _access;

  Future<void> init() async {
    _access = await _repository.load();
    notifyListeners();
  }

  Future<void> _update(GameAccess next) async {
    _access = next;
    notifyListeners();
    await _repository.save(next);
  }

  Future<void> setGameEnabled(GameId id, bool enabled) =>
      _update(_access.withGameEnabled(id, enabled));

  Future<void> enableAllGames() => _update(
        _access.copyWith(enabled: {for (final id in GameId.values) id: true}),
      );

  Future<void> setPlayMode(PlayMode mode) =>
      _update(_access.copyWith(playMode: mode));

  Future<void> setGuidedOrder(List<GameId> order) =>
      _update(_access.copyWith(guidedOrder: order));

  /// Whether the child may open [id] right now.
  ///
  /// Free mode: any enabled game. Guided mode: only the current guided game.
  bool canPlay(GameId id, ProgressData progress) {
    if (!_access.isEnabled(id)) return false;
    if (_access.playMode == PlayMode.free) return true;
    return currentGuidedGame(progress) == id;
  }

  /// In guided mode the "current" game is the enabled game, in guided order,
  /// with the fewest completions — so finishing one gently opens the next.
  GameId? currentGuidedGame(ProgressData progress) {
    GameId? candidate;
    var best = -1;
    for (final id in _access.guidedOrder) {
      if (!_access.isEnabled(id)) continue;
      final completions = progress.of(id).completions;
      if (best == -1 || completions < best) {
        best = completions;
        candidate = id;
      }
    }
    return candidate;
  }

  Future<void> reloadFromStore() async {
    _access = await _repository.load();
    notifyListeners();
  }
}
