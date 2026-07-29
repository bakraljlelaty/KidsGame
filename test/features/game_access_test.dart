import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/parent_dashboard/game_access.dart';
import 'package:little_wonder_world/features/parent_dashboard/game_access_controller.dart';
import 'package:little_wonder_world/features/progress/progress_data.dart';
import 'package:little_wonder_world/shared/models/game_id.dart';

ProgressData progressWithCompletions(Map<GameId, int> completions) =>
    ProgressData(
      games: {
        for (final e in completions.entries)
          e.key: GameProgress(completions: e.value),
      },
    );

void main() {
  group('GameAccess defaults', () {
    test('every game is enabled, free mode, guided order = declaration order',
        () {
      final access = GameAccess();
      for (final id in GameId.values) {
        expect(access.isEnabled(id), isTrue, reason: '$id should be enabled');
      }
      expect(access.enabledGames, GameId.values);
      expect(access.playMode, PlayMode.free);
      expect(access.guidedOrder, GameId.values);
    });
  });

  group('persistence', () {
    test('withGameEnabled survives a repository round-trip', () async {
      final store = InMemoryStore();
      final repo = GameAccessRepository(store);

      await repo.save(GameAccess().withGameEnabled(GameId.bubblePop, false));

      final loaded = await repo.load();
      expect(loaded.isEnabled(GameId.bubblePop), isFalse);
      for (final id in GameId.values.where((g) => g != GameId.bubblePop)) {
        expect(loaded.isEnabled(id), isTrue);
      }
      expect(loaded.enabledGames, isNot(contains(GameId.bubblePop)));
    });

    test('JSON round-trip preserves a custom guidedOrder', () {
      final order = GameId.values.reversed.toList();
      final access = GameAccess(
        playMode: PlayMode.guided,
        guidedOrder: order,
      );

      final decoded = GameAccess.fromJson(access.toJson());
      expect(decoded.guidedOrder, order);
      expect(decoded.playMode, PlayMode.guided);
    });

    test('controller round-trip via a new controller on the same store',
        () async {
      final store = InMemoryStore();
      final controller = GameAccessController(GameAccessRepository(store));
      await controller.init();
      final order = [
        GameId.bedtimeRoutine,
        GameId.feedAnimals,
        GameId.muddyPig,
        GameId.bubblePop,
        GameId.buildRocket,
        GameId.dancingSocks,
      ];
      await controller.setGuidedOrder(order);
      await controller.setPlayMode(PlayMode.guided);
      await controller.setGameEnabled(GameId.muddyPig, false);

      final revived = GameAccessController(GameAccessRepository(store));
      await revived.init();
      expect(revived.access.guidedOrder, order);
      expect(revived.access.playMode, PlayMode.guided);
      expect(revived.access.isEnabled(GameId.muddyPig), isFalse);
    });
  });

  group('canPlay', () {
    test('a disabled game can never be played', () async {
      final controller =
          GameAccessController(GameAccessRepository(InMemoryStore()));
      await controller.init();
      await controller.setGameEnabled(GameId.dancingSocks, false);

      final progress = ProgressData();
      expect(controller.canPlay(GameId.dancingSocks, progress), isFalse);
      expect(controller.canPlay(GameId.feedAnimals, progress), isTrue);
    });
  });

  group('guided mode', () {
    test('current guided game is the first enabled game with fewest '
        'completions and advances as completions grow', () async {
      final controller =
          GameAccessController(GameAccessRepository(InMemoryStore()));
      await controller.init();
      await controller.setPlayMode(PlayMode.guided);

      // Nothing played yet: the first game in guided order is current.
      expect(controller.currentGuidedGame(ProgressData()), GameId.feedAnimals);

      // Completing the first game moves guidance to the second.
      var progress = progressWithCompletions({GameId.feedAnimals: 1});
      expect(controller.currentGuidedGame(progress), GameId.bubblePop);
      expect(controller.canPlay(GameId.bubblePop, progress), isTrue);
      expect(controller.canPlay(GameId.feedAnimals, progress), isFalse,
          reason: 'guided mode only opens the current game');

      // And so on down the order.
      progress = progressWithCompletions({
        GameId.feedAnimals: 1,
        GameId.bubblePop: 1,
      });
      expect(controller.currentGuidedGame(progress), GameId.dancingSocks);

      // Once every game has one completion, guidance wraps to the first.
      progress = progressWithCompletions({
        for (final id in GameId.values) id: 1,
      });
      expect(controller.currentGuidedGame(progress), GameId.feedAnimals);
    });

    test('disabled games are skipped by guidance', () async {
      final controller =
          GameAccessController(GameAccessRepository(InMemoryStore()));
      await controller.init();
      await controller.setPlayMode(PlayMode.guided);
      await controller.setGameEnabled(GameId.feedAnimals, false);

      expect(controller.currentGuidedGame(ProgressData()), GameId.bubblePop);

      await controller.setGameEnabled(GameId.bubblePop, false);
      expect(
          controller.currentGuidedGame(ProgressData()), GameId.dancingSocks);

      final progress = progressWithCompletions({GameId.dancingSocks: 2});
      expect(controller.currentGuidedGame(progress), GameId.muddyPig);
      expect(controller.canPlay(GameId.bubblePop, progress), isFalse);
    });
  });
}
