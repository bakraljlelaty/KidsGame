import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/shared/models/development_stage.dart';

void main() {
  group('StageConfig.of', () {
    test('returns the config for its own stage', () {
      for (final stage in DevelopmentStage.values) {
        expect(StageConfig.of(stage).stage, stage);
      }
    });

    test('hint delays are 3, 5 and 7 seconds', () {
      expect(StageConfig.of(DevelopmentStage.explorer).hintDelay,
          const Duration(seconds: 3));
      expect(StageConfig.of(DevelopmentStage.helper).hintDelay,
          const Duration(seconds: 5));
      expect(StageConfig.of(DevelopmentStage.littleThinker).hintDelay,
          const Duration(seconds: 7));
    });

    test('maxActiveTargets is 1, 2 and 3', () {
      expect(StageConfig.of(DevelopmentStage.explorer).maxActiveTargets, 1);
      expect(StageConfig.of(DevelopmentStage.helper).maxActiveTargets, 2);
      expect(
          StageConfig.of(DevelopmentStage.littleThinker).maxActiveTargets, 3);
    });

    test('puzzlePieceCount is 2, 3 and 4', () {
      expect(StageConfig.of(DevelopmentStage.explorer).puzzlePieceCount, 2);
      expect(StageConfig.of(DevelopmentStage.helper).puzzlePieceCount, 3);
      expect(
          StageConfig.of(DevelopmentStage.littleThinker).puzzlePieceCount, 4);
    });

    test('routineStepCount is 1, 2 and 5', () {
      expect(StageConfig.of(DevelopmentStage.explorer).routineStepCount, 1);
      expect(StageConfig.of(DevelopmentStage.helper).routineStepCount, 2);
      expect(
          StageConfig.of(DevelopmentStage.littleThinker).routineStepCount, 5);
    });

    test('explorer items are larger than littleThinker items', () {
      expect(
        StageConfig.of(DevelopmentStage.explorer).itemScale,
        greaterThan(StageConfig.of(DevelopmentStage.littleThinker).itemScale),
      );
    });

    test('only littleThinker uses sequences', () {
      expect(StageConfig.of(DevelopmentStage.explorer).usesSequences, isFalse);
      expect(StageConfig.of(DevelopmentStage.helper).usesSequences, isFalse);
      expect(StageConfig.of(DevelopmentStage.littleThinker).usesSequences,
          isTrue);
    });
  });

  group('DevelopmentStage.next', () {
    test('advances explorer -> helper -> littleThinker -> null', () {
      expect(DevelopmentStage.explorer.next, DevelopmentStage.helper);
      expect(DevelopmentStage.helper.next, DevelopmentStage.littleThinker);
      expect(DevelopmentStage.littleThinker.next, isNull);
    });
  });
}
