import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/app/app_services.dart';
import 'package:little_wonder_world/config/app_config.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/settings/app_settings.dart';
import 'package:little_wonder_world/features/settings/settings_controller.dart';
import 'package:little_wonder_world/shared/models/game_id.dart';
import 'package:little_wonder_world/shared/models/skill.dart';

Future<AppServices> bootstrap(InMemoryStore store) => AppServices.bootstrap(
      store: store,
      enableAutoTick: false,
      initAudio: false,
    );

Future<void> seedChildData(AppServices services) async {
  await services.profile.setNickname('Bo');
  await services.settings.setMusicEnabled(false);
  await services.progress.recordGameStarted(GameId.feedAnimals);
  await services.progress.recordCompletion(
    GameId.feedAnimals,
    skills: const [Skill.tapping],
    usedHints: false,
    playTime: const Duration(seconds: 20),
  );
  await services.rewards.awardCompletion(GameId.feedAnimals);
  await services.stickerBook.placeSticker('feed_carrot', 'meadow', 0.4, 0.6);
}

void main() {
  group('AppServices.resetProgress', () {
    test('clears progress, rewards and sticker book but keeps profile and '
        'settings', () async {
      final store = InMemoryStore();
      final services = await bootstrap(store);
      await seedChildData(services);

      // Sanity: data exists before the reset.
      expect(services.progress.data.totalCompletions, 1);
      expect(services.rewards.data.totalStars, 1);
      expect(services.stickerBook.data.placements, hasLength(1));

      await services.resetProgress();

      expect(services.progress.data.totalCompletions, 0);
      expect(services.progress.data.totalAttempts, 0);
      expect(services.progress.data.skillPlays, isEmpty);
      expect(services.rewards.data.totalStars, 0);
      expect(services.rewards.data.earnedStickerIds, isEmpty);
      expect(services.rewards.data.decorationPoints, 0);
      expect(services.stickerBook.data.placements, isEmpty);

      // Profile and settings survive.
      expect(services.profile.profile.nickname, 'Bo');
      expect(services.settings.settings.musicEnabled, isFalse);

      // And the cleared state is what a restart loads too.
      final restarted = await bootstrap(store);
      expect(restarted.progress.data.totalCompletions, 0);
      expect(restarted.rewards.data.totalStars, 0);
      expect(restarted.stickerBook.data.placements, isEmpty);
      expect(restarted.profile.profile.nickname, 'Bo');
      expect(restarted.settings.settings.musicEnabled, isFalse);
    });
  });

  group('AppServices.deleteAllData', () {
    test('empties the store and returns every controller to defaults',
        () async {
      final store = InMemoryStore();
      final services = await bootstrap(store);
      await seedChildData(services);
      expect(await store.keys(), isNotEmpty);

      await services.deleteAllData();

      // The store is wiped. One caveat: SessionController.init (run by
      // reloadFromStore) immediately re-saves a *fresh* session_usage
      // document while rolling the day (session_controller.dart,
      // _rollDayIfNeeded), so that single benign key may remain — but it
      // must contain no play data.
      final remaining = await store.keys();
      expect(remaining.difference({'session_usage'}), isEmpty,
          reason: 'only a fresh session_usage doc may survive deleteAllData');
      expect(services.session.usage.playedTodayMs, 0);
      expect(services.session.usage.lastSessionEndEpochMs, isNull);
      expect(services.session.usage.parentUnlockEpochMs, isNull);

      expect(services.profile.profile.nickname, '');
      expect(services.settings.settings.musicEnabled, isTrue);
      expect(services.settings.settings.parentPin, AppConfig.defaultParentPin);
      expect(services.progress.data.totalCompletions, 0);
      expect(services.progress.data.totalAttempts, 0);
      expect(services.rewards.data.totalStars, 0);
      expect(services.rewards.data.earnedStickerIds, isEmpty);
      expect(services.stickerBook.data.placements, isEmpty);
      expect(services.gameAccess.access.enabledGames, GameId.values);
    });
  });

  group('parent PIN', () {
    test('defaults to AppConfig.defaultParentPin and checkPin matches',
        () async {
      final services = await bootstrap(InMemoryStore());
      expect(services.settings.settings.parentPin, AppConfig.defaultParentPin);
      expect(services.settings.settings.usesDefaultPin, isTrue);
      expect(services.settings.checkPin(AppConfig.defaultParentPin), isTrue);
      expect(services.settings.checkPin('0000'), isFalse);
    });

    test('setParentPin persists across a new controller on the same store',
        () async {
      final store = InMemoryStore();
      final services = await bootstrap(store);
      await services.settings.setParentPin('1379');
      expect(services.settings.checkPin('1379'), isTrue);
      expect(services.settings.checkPin(AppConfig.defaultParentPin), isFalse);

      final revived = SettingsController(SettingsRepository(store));
      await revived.init();
      expect(revived.settings.parentPin, '1379');
      expect(revived.settings.usesDefaultPin, isFalse);
      expect(revived.checkPin('1379'), isTrue);
    });

    test('restoreDefaults resets settings but KEEPS a changed PIN', () async {
      final store = InMemoryStore();
      final services = await bootstrap(store);
      await services.settings.setParentPin('1379');
      await services.settings.setMusicEnabled(false);
      await services.settings.setReducedMotion(true);

      await services.settings.restoreDefaults();

      expect(services.settings.settings.musicEnabled, isTrue);
      expect(services.settings.settings.reducedMotion, isFalse);
      expect(services.settings.settings.parentPin, '1379');
      expect(services.settings.checkPin('1379'), isTrue);

      // The kept PIN is also what persists.
      final stored = await SettingsRepository(store).load();
      expect(stored.parentPin, '1379');
      expect(stored.musicEnabled, isTrue);
    });
  });
}
