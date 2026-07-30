import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/profiles/child_profile.dart';
import 'package:little_wonder_world/features/profiles/profile_controller.dart';
import 'package:little_wonder_world/features/progress/progress_controller.dart';
import 'package:little_wonder_world/features/progress/progress_data.dart';
import 'package:little_wonder_world/features/rewards/reward_data.dart';
import 'package:little_wonder_world/features/rewards/rewards_controller.dart';
import 'package:little_wonder_world/shared/models/age_band.dart';
import 'package:little_wonder_world/shared/models/skill.dart';
import 'package:little_wonder_world/shared/models/subject.dart';

class AcademyHarness {
  AcademyHarness() : store = InMemoryStore() {
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

  Future<void> complete(Subject subject, {required bool usedHints}) =>
      progress.recordActivityCompletion(
        subject,
        skills: const [Skill.colors, Skill.tapping],
        usedHints: usedHints,
        playTime: const Duration(seconds: 20),
      );
}

void main() {
  group('RewardsController.awardActivityCompletion', () {
    test('subject stars increment and count into totalStars', () async {
      final rewards = RewardsController(RewardRepository(InMemoryStore()));
      await rewards.init();

      final first = await rewards.awardActivityCompletion(Subject.colors);
      expect(first.totalStarsForGame, 1);
      expect(rewards.data.starsForSubject(Subject.colors), 1);

      final second = await rewards.awardActivityCompletion(Subject.colors);
      expect(second.totalStarsForGame, 2);
      expect(rewards.data.starsForSubject(Subject.colors), 2);

      await rewards.awardActivityCompletion(Subject.shapes);
      expect(rewards.data.starsForSubject(Subject.shapes), 1);
      expect(rewards.data.starsForSubject(Subject.colors), 2);
      expect(rewards.data.totalStars, 3,
          reason: 'totalStars must include subject stars');
    });

    test('a sticker joins the celebration only when a unit completed',
        () async {
      final rewards = RewardsController(RewardRepository(InMemoryStore()));
      await rewards.init();

      final plain = await rewards.awardActivityCompletion(Subject.colors);
      expect(plain.sticker, isNull);
      expect(plain.isNewSticker, isFalse);
      expect(rewards.data.earnedStickerIds, isEmpty);

      final celebrated = await rewards.awardActivityCompletion(
        Subject.colors,
        unitCompleted: true,
      );
      expect(celebrated.isNewSticker, isTrue);
      expect(celebrated.sticker, isNotNull);
      expect(rewards.data.earnedStickerIds, hasLength(1));
      expect(rewards.data.earnedStickerIds, contains(celebrated.sticker!.id));

      // Back to plain completions: no further stickers.
      final after = await rewards.awardActivityCompletion(Subject.colors);
      expect(after.sticker, isNull);
      expect(after.isNewSticker, isFalse);
      expect(rewards.data.earnedStickerIds, hasLength(1));
    });
  });

  group('ProgressController academy activity statistics', () {
    test('recordActivityStarted / Hint / Completion update subject counts',
        () async {
      final h = AcademyHarness();
      await h.init();

      await h.progress.recordActivityStarted(Subject.animals);
      await h.progress.recordActivityStarted(Subject.animals);
      await h.progress.recordActivityHint(Subject.animals);
      await h.progress.recordActivityCompletion(
        Subject.animals,
        skills: const [Skill.animals, Skill.matching],
        usedHints: true,
        playTime: const Duration(seconds: 40),
      );

      final stats = h.progress.data.ofSubject(Subject.animals);
      expect(stats.attempts, 2);
      expect(stats.hintsShown, 1);
      expect(stats.completions, 1);
      expect(stats.completionsWithoutHints, 0);
      expect(stats.playMs, 40000);
      expect(h.progress.data.skillPlays[Skill.animals], 1);
      expect(h.progress.data.skillPlays[Skill.matching], 1);

      // Subject statistics feed the overall totals.
      expect(h.progress.data.totalAttempts, 2);
      expect(h.progress.data.totalCompletions, 1);
      expect(h.progress.data.totalHintsShown, 1);
      expect(h.progress.data.totalPlayMs, 40000);

      // Other subjects stay untouched.
      expect(h.progress.data.ofSubject(Subject.colors).attempts, 0);
    });

    test(
        'hint-free activity completions advance the band one step and reset '
        'the streak', () async {
      final h = AcademyHarness();
      await h.init();
      expect(h.profile.profile.autoStageProgression, isTrue);
      expect(h.profile.profile.band, AgeBand.twoToThree);

      const needed = ProgressController.advanceAfterRelaxedCompletions;
      for (var i = 0; i < needed - 1; i++) {
        await h.complete(Subject.colors, usedHints: false);
      }
      expect(h.profile.profile.band, AgeBand.twoToThree,
          reason: 'one completion short of the threshold');
      expect(h.progress.data.relaxedCompletionStreak, needed - 1);

      await h.complete(Subject.colors, usedHints: false);
      expect(h.profile.profile.band, AgeBand.threeToFour);
      expect(h.progress.data.relaxedCompletionStreak, 0);

      // The band change was persisted.
      final stored = await ProfileRepository(h.store).load();
      expect(stored.band, AgeBand.threeToFour);
    });

    test('activity completions with hints never advance the band', () async {
      final h = AcademyHarness();
      await h.init();

      const needed = ProgressController.advanceAfterRelaxedCompletions;
      for (var i = 0; i < needed + 2; i++) {
        await h.complete(Subject.colors, usedHints: true);
      }
      expect(h.profile.profile.band, AgeBand.twoToThree);
      expect(h.progress.data.relaxedCompletionStreak, 0);
    });
  });
}
