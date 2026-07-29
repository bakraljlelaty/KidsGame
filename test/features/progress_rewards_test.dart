import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/profiles/child_profile.dart';
import 'package:little_wonder_world/features/profiles/profile_controller.dart';
import 'package:little_wonder_world/features/progress/progress_controller.dart';
import 'package:little_wonder_world/features/progress/progress_data.dart';
import 'package:little_wonder_world/features/rewards/reward_data.dart';
import 'package:little_wonder_world/features/rewards/rewards_controller.dart';
import 'package:little_wonder_world/features/rewards/sticker_catalog.dart';
import 'package:little_wonder_world/shared/models/development_stage.dart';
import 'package:little_wonder_world/shared/models/game_id.dart';
import 'package:little_wonder_world/shared/models/skill.dart';

class ProgressHarness {
  ProgressHarness() : store = InMemoryStore() {
    profile = ProfileController(ProfileRepository(store));
    progress = ProgressController(ProgressRepository(store), profile);
  }

  final InMemoryStore store;
  late final ProfileController profile;
  late final ProgressController progress;

  Future<void> init() async {
    await profile.init();
    await progress.init();
  }

  Future<void> complete(GameId id, {required bool usedHints}) =>
      progress.recordCompletion(
        id,
        skills: const [Skill.tapping, Skill.animals],
        usedHints: usedHints,
        playTime: const Duration(seconds: 30),
      );
}

void main() {
  group('ProgressController', () {
    test('recordGameStarted / recordHintShown / recordCompletion update counts',
        () async {
      final h = ProgressHarness();
      await h.init();

      await h.progress.recordGameStarted(GameId.feedAnimals);
      await h.progress.recordGameStarted(GameId.feedAnimals);
      await h.progress.recordHintShown(GameId.feedAnimals);
      await h.progress.recordCompletion(
        GameId.feedAnimals,
        skills: const [Skill.tapping, Skill.animals],
        usedHints: true,
        playTime: const Duration(seconds: 45),
      );

      final game = h.progress.data.of(GameId.feedAnimals);
      expect(game.attempts, 2);
      expect(game.hintsShown, 1);
      expect(game.completions, 1);
      expect(game.completionsWithoutHints, 0);
      expect(game.playMs, 45000);
      expect(h.progress.data.skillPlays[Skill.tapping], 1);
      expect(h.progress.data.skillPlays[Skill.animals], 1);

      // Untouched games stay at zero.
      expect(h.progress.data.of(GameId.bubblePop).attempts, 0);
    });

    test('hint-free completions grow the relaxed streak; hinted ones do not',
        () async {
      final h = ProgressHarness();
      await h.init();

      await h.complete(GameId.bubblePop, usedHints: false);
      expect(h.progress.data.relaxedCompletionStreak, 1);

      await h.complete(GameId.bubblePop, usedHints: true);
      expect(h.progress.data.relaxedCompletionStreak, 1);

      await h.complete(GameId.muddyPig, usedHints: false);
      expect(h.progress.data.relaxedCompletionStreak, 2);
    });

    test(
        'with autoStageProgression on, the stage advances exactly one step '
        'after enough relaxed completions and the streak resets', () async {
      final h = ProgressHarness();
      await h.init();
      expect(h.profile.profile.autoStageProgression, isTrue);
      expect(h.profile.profile.stage, DevelopmentStage.explorer);

      const needed = ProgressController.advanceAfterRelaxedCompletions;
      for (var i = 0; i < needed - 1; i++) {
        await h.complete(GameId.feedAnimals, usedHints: false);
      }
      expect(h.profile.profile.stage, DevelopmentStage.explorer);
      expect(h.progress.data.relaxedCompletionStreak, needed - 1);

      await h.complete(GameId.feedAnimals, usedHints: false);
      expect(h.profile.profile.stage, DevelopmentStage.helper);
      expect(h.progress.data.relaxedCompletionStreak, 0);

      // One more completion does not jump another stage.
      await h.complete(GameId.feedAnimals, usedHints: false);
      expect(h.profile.profile.stage, DevelopmentStage.helper);
      expect(h.progress.data.relaxedCompletionStreak, 1);

      // The stage change was persisted.
      final storedProfile = await ProfileRepository(h.store).load();
      expect(storedProfile.stage, DevelopmentStage.helper);
    });

    test('with autoStageProgression off the stage never advances', () async {
      final h = ProgressHarness();
      await h.init();
      await h.profile.setAutoStageProgression(false);

      const needed = ProgressController.advanceAfterRelaxedCompletions;
      for (var i = 0; i < needed + 2; i++) {
        await h.complete(GameId.feedAnimals, usedHints: false);
      }
      expect(h.profile.profile.stage, DevelopmentStage.explorer);
      expect(h.progress.data.relaxedCompletionStreak, needed + 2);
    });

    test('completions with hints never advance the stage', () async {
      final h = ProgressHarness();
      await h.init();

      const needed = ProgressController.advanceAfterRelaxedCompletions;
      for (var i = 0; i < needed + 2; i++) {
        await h.complete(GameId.feedAnimals, usedHints: true);
      }
      expect(h.profile.profile.stage, DevelopmentStage.explorer);
      expect(h.progress.data.relaxedCompletionStreak, 0);
    });
  });

  group('RewardsController.awardCompletion', () {
    test('stars and decoration points increment per completion', () async {
      final rewards = RewardsController(RewardRepository(InMemoryStore()));
      await rewards.init();

      final first = await rewards.awardCompletion(GameId.bubblePop);
      expect(first.totalStarsForGame, 1);
      expect(rewards.data.starsFor(GameId.bubblePop), 1);
      expect(rewards.data.decorationPoints, 1);

      final second = await rewards.awardCompletion(GameId.bubblePop);
      expect(second.totalStarsForGame, 2);
      expect(rewards.data.starsFor(GameId.bubblePop), 2);
      expect(rewards.data.decorationPoints, 2);

      // Stars are tracked per game.
      await rewards.awardCompletion(GameId.muddyPig);
      expect(rewards.data.starsFor(GameId.muddyPig), 1);
      expect(rewards.data.starsFor(GameId.bubblePop), 2);
      expect(rewards.data.totalStars, 3);
      expect(rewards.data.decorationPoints, 3);
    });

    test(
        'the first three completions earn the catalog stickers in order; '
        'the fourth repeats without a new sticker', () async {
      final rewards = RewardsController(RewardRepository(InMemoryStore()));
      await rewards.init();

      final catalog = StickerCatalog.forGame(GameId.feedAnimals);
      expect(catalog, hasLength(3));

      for (var i = 0; i < 3; i++) {
        final reward = await rewards.awardCompletion(GameId.feedAnimals);
        expect(reward.isNewSticker, isTrue, reason: 'completion ${i + 1}');
        expect(reward.sticker, isNotNull);
        expect(reward.sticker!.id, catalog[i].id,
            reason: 'stickers unlock in catalog order');
      }
      expect(
        rewards.data.earnedStickerIds,
        catalog.map((s) => s.id).toSet(),
      );

      final fourth = await rewards.awardCompletion(GameId.feedAnimals);
      expect(fourth.isNewSticker, isFalse);
      expect(fourth.sticker, isNotNull,
          reason: 'the overlay still celebrates an earned sticker');
      expect(rewards.data.earnedStickerIds, hasLength(3));
    });

    test('reset clears stars, stickers and decoration points', () async {
      final store = InMemoryStore();
      final rewards = RewardsController(RewardRepository(store));
      await rewards.init();
      await rewards.awardCompletion(GameId.buildRocket);
      await rewards.awardCompletion(GameId.buildRocket);
      expect(rewards.data.totalStars, 2);

      await rewards.reset();
      expect(rewards.data.totalStars, 0);
      expect(rewards.data.earnedStickerIds, isEmpty);
      expect(rewards.data.decorationPoints, 0);
      expect(rewards.earnedStickers, isEmpty);

      // The cleared state is what a fresh load sees too.
      final reloaded = await RewardRepository(store).load();
      expect(reloaded.totalStars, 0);
      expect(reloaded.earnedStickerIds, isEmpty);
      expect(reloaded.decorationPoints, 0);
    });
  });
}
