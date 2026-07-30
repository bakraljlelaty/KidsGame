import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/profiles/child_profile.dart';
import 'package:little_wonder_world/shared/models/age_band.dart';
import 'package:little_wonder_world/shared/models/development_stage.dart';

/// Writes a v1-shaped profile envelope straight into the store, the way the
/// shipped v1 app persisted it.
Future<InMemoryStore> storeWithV1Profile(Map<String, dynamic> data) async {
  final store = InMemoryStore();
  await store.write('profile', jsonEncode({'v': 1, 'data': data}));
  return store;
}

void main() {
  group('v1 -> v2 profile migration', () {
    test("stage 'helper' migrates to threeToFour and keeps the nickname",
        () async {
      final store = await storeWithV1Profile({
        'nickname': 'x',
        'stage': 'helper',
        'ageGroup': 'around_three',
        'avatarId': 'star',
        'languageCode': 'en',
        'autoStageProgression': true,
      });

      final profile = await ProfileRepository(store).load();
      expect(profile.band, AgeBand.threeToFour);
      expect(profile.nickname, 'x');
      expect(profile.avatarId, 'star');
      expect(profile.languageCode, 'en');
      expect(profile.autoStageProgression, isTrue);
    });

    test("stage 'little_thinker' migrates to fourToFive", () async {
      final store = await storeWithV1Profile({
        'nickname': 'thinker',
        'stage': 'little_thinker',
        'ageGroup': 'around_three',
        'avatarId': 'star',
        'languageCode': 'en',
        'autoStageProgression': true,
      });

      final profile = await ProfileRepository(store).load();
      expect(profile.band, AgeBand.fourToFive);
      expect(profile.nickname, 'thinker');
    });

    test(
        "a document without band or stage falls back to the age group: "
        "'around_two' -> twoToThree", () async {
      final store = await storeWithV1Profile({
        'nickname': 'tiny',
        'ageGroup': 'around_two',
        'avatarId': 'star',
        'languageCode': 'en',
        'autoStageProgression': true,
      });

      final profile = await ProfileRepository(store).load();
      expect(profile.band, AgeBand.twoToThree);
      expect(profile.nickname, 'tiny');
    });

    test("without band or stage, ageGroup 'around_three' -> threeToFour",
        () async {
      final store = await storeWithV1Profile({
        'nickname': 'three',
        'ageGroup': 'around_three',
        'avatarId': 'star',
        'languageCode': 'en',
        'autoStageProgression': true,
      });

      final profile = await ProfileRepository(store).load();
      expect(profile.band, AgeBand.threeToFour);
    });

    test('saving after migration persists the current (v2) schema', () async {
      final store = await storeWithV1Profile({
        'nickname': 'x',
        'stage': 'helper',
        'ageGroup': 'around_three',
        'avatarId': 'star',
        'languageCode': 'en',
        'autoStageProgression': true,
      });

      final repository = ProfileRepository(store);
      final migrated = await repository.load();
      await repository.save(migrated);

      final envelope =
          jsonDecode(store.snapshot['profile']!) as Map<String, dynamic>;
      expect(envelope['v'], 2);
      final data = (envelope['data'] as Map).cast<String, dynamic>();
      expect(data['band'], 'three_four');
      expect(data.containsKey('stage'), isFalse);
      expect(data.containsKey('ageGroup'), isFalse);
    });
  });

  group('ChildProfile.stage', () {
    test('derives the v1 stage from the band', () {
      expect(const ChildProfile(band: AgeBand.twoToThree).stage,
          DevelopmentStage.explorer);
      expect(const ChildProfile(band: AgeBand.threeToFour).stage,
          DevelopmentStage.helper);
      expect(const ChildProfile(band: AgeBand.fourToFive).stage,
          DevelopmentStage.littleThinker);
      expect(const ChildProfile(band: AgeBand.fiveToSix).stage,
          DevelopmentStage.littleThinker);
    });
  });
}
