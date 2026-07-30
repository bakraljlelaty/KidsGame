import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/shared/models/age_band.dart';
import 'package:little_wonder_world/shared/models/development_stage.dart';

void main() {
  group('BandConfig.of', () {
    test('returns the config for its own band', () {
      for (final band in AgeBand.values) {
        expect(BandConfig.of(band).band, band);
      }
    });

    test('hint delay grows gently with the band (3/5/6/7 s)', () {
      expect(BandConfig.of(AgeBand.twoToThree).hintDelay,
          const Duration(seconds: 3));
      expect(BandConfig.of(AgeBand.threeToFour).hintDelay,
          const Duration(seconds: 5));
      expect(BandConfig.of(AgeBand.fourToFive).hintDelay,
          const Duration(seconds: 6));
      expect(BandConfig.of(AgeBand.fiveToSix).hintDelay,
          const Duration(seconds: 7));
    });

    test('choiceCount ramps 2/3/4/4', () {
      expect(BandConfig.of(AgeBand.twoToThree).choiceCount, 2);
      expect(BandConfig.of(AgeBand.threeToFour).choiceCount, 3);
      expect(BandConfig.of(AgeBand.fourToFive).choiceCount, 4);
      expect(BandConfig.of(AgeBand.fiveToSix).choiceCount, 4);
    });

    test('memoryPairCount ramps 2/3/4/6', () {
      expect(BandConfig.of(AgeBand.twoToThree).memoryPairCount, 2);
      expect(BandConfig.of(AgeBand.threeToFour).memoryPairCount, 3);
      expect(BandConfig.of(AgeBand.fourToFive).memoryPairCount, 4);
      expect(BandConfig.of(AgeBand.fiveToSix).memoryPairCount, 6);
    });

    test('patternLength ramps 2/2/3/4', () {
      expect(BandConfig.of(AgeBand.twoToThree).patternLength, 2);
      expect(BandConfig.of(AgeBand.threeToFour).patternLength, 2);
      expect(BandConfig.of(AgeBand.fourToFive).patternLength, 3);
      expect(BandConfig.of(AgeBand.fiveToSix).patternLength, 4);
    });

    test('countingMax ramps 3/5/7/10', () {
      expect(BandConfig.of(AgeBand.twoToThree).countingMax, 3);
      expect(BandConfig.of(AgeBand.threeToFour).countingMax, 5);
      expect(BandConfig.of(AgeBand.fourToFive).countingMax, 7);
      expect(BandConfig.of(AgeBand.fiveToSix).countingMax, 10);
    });

    test('sortBinCount ramps 2/2/3/3', () {
      expect(BandConfig.of(AgeBand.twoToThree).sortBinCount, 2);
      expect(BandConfig.of(AgeBand.threeToFour).sortBinCount, 2);
      expect(BandConfig.of(AgeBand.fourToFive).sortBinCount, 3);
      expect(BandConfig.of(AgeBand.fiveToSix).sortBinCount, 3);
    });

    test('letters are disabled only for the youngest band', () {
      expect(BandConfig.of(AgeBand.twoToThree).lettersEnabled, isFalse);
      expect(BandConfig.of(AgeBand.threeToFour).lettersEnabled, isTrue);
      expect(BandConfig.of(AgeBand.fourToFive).lettersEnabled, isTrue);
      expect(BandConfig.of(AgeBand.fiveToSix).lettersEnabled, isTrue);
    });
  });

  group('AgeBand.next', () {
    test('walks the four bands in order and ends null at fiveToSix', () {
      expect(AgeBand.twoToThree.next, AgeBand.threeToFour);
      expect(AgeBand.threeToFour.next, AgeBand.fourToFive);
      expect(AgeBand.fourToFive.next, AgeBand.fiveToSix);
      expect(AgeBand.fiveToSix.next, isNull);
    });

    test('the chain visits every band exactly once', () {
      final visited = <AgeBand>[];
      AgeBand? band = AgeBand.twoToThree;
      while (band != null) {
        visited.add(band);
        band = band.next;
      }
      expect(visited, AgeBand.values);
    });
  });

  group('legacy stage mapping', () {
    test('legacyStage maps bands to the v1 stages', () {
      expect(AgeBand.twoToThree.legacyStage, DevelopmentStage.explorer);
      expect(AgeBand.threeToFour.legacyStage, DevelopmentStage.helper);
      expect(AgeBand.fourToFive.legacyStage, DevelopmentStage.littleThinker);
      expect(AgeBand.fiveToSix.legacyStage, DevelopmentStage.littleThinker);
    });

    test('fromLegacyStage maps every v1 stage to its band', () {
      expect(AgeBand.fromLegacyStage(DevelopmentStage.explorer),
          AgeBand.twoToThree);
      expect(AgeBand.fromLegacyStage(DevelopmentStage.helper),
          AgeBand.threeToFour);
      expect(AgeBand.fromLegacyStage(DevelopmentStage.littleThinker),
          AgeBand.fourToFive);
    });

    test('fromLegacyStage round-trips through legacyStage', () {
      for (final stage in DevelopmentStage.values) {
        expect(AgeBand.fromLegacyStage(stage).legacyStage, stage,
            reason: 'stage ${stage.storageKey} must survive the round trip');
      }
    });
  });

  group('AgeBand.fromStorageKey', () {
    test('resolves every storage key and falls back to twoToThree', () {
      for (final band in AgeBand.values) {
        expect(AgeBand.fromStorageKey(band.storageKey), band);
      }
      expect(AgeBand.fromStorageKey('nonsense'), AgeBand.twoToThree);
      expect(AgeBand.fromStorageKey(null), AgeBand.twoToThree);
    });
  });
}
