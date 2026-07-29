/// The three parent-selectable development stages.
enum DevelopmentStage {
  explorer('explorer'),
  helper('helper'),
  littleThinker('little_thinker');

  const DevelopmentStage(this.storageKey);

  final String storageKey;

  static DevelopmentStage fromStorageKey(String? key) {
    for (final s in DevelopmentStage.values) {
      if (s.storageKey == key) return s;
    }
    return DevelopmentStage.explorer;
  }

  DevelopmentStage? get next => switch (this) {
        DevelopmentStage.explorer => DevelopmentStage.helper,
        DevelopmentStage.helper => DevelopmentStage.littleThinker,
        DevelopmentStage.littleThinker => null,
      };
}

/// Difficulty tuning for one development stage.
///
/// Mini-games read these values instead of branching on the stage enum, so
/// balance changes happen in one place.
class StageConfig {
  const StageConfig({
    required this.stage,
    required this.hintDelay,
    required this.maxActiveTargets,
    required this.distractorCount,
    required this.puzzlePieceCount,
    required this.maxCountingNumber,
    required this.routineStepCount,
    required this.usesSequences,
    required this.itemScale,
  });

  final DevelopmentStage stage;

  /// Idle time before the automatic hint animation appears.
  final Duration hintDelay;

  /// How many "correct" targets a scene shows at once (1..3).
  final int maxActiveTargets;

  /// How many wrong-choice items sit alongside the correct one.
  final int distractorCount;

  /// Piece count for puzzle-style activities (rocket).
  final int puzzlePieceCount;

  /// Highest number used by counting prompts (0 = no counting).
  final int maxCountingNumber;

  /// Steps of a multi-step routine the child performs (pig bath, bedtime).
  final int routineStepCount;

  /// Whether ordered mini-sequences ("blue, then yellow") are used.
  final bool usesSequences;

  /// Relative size multiplier for interactive objects (Explorer items are
  /// extra large).
  final double itemScale;

  static const StageConfig explorer = StageConfig(
    stage: DevelopmentStage.explorer,
    hintDelay: Duration(seconds: 3),
    maxActiveTargets: 1,
    distractorCount: 0,
    puzzlePieceCount: 2,
    maxCountingNumber: 0,
    routineStepCount: 1,
    usesSequences: false,
    itemScale: 1.25,
  );

  static const StageConfig helper = StageConfig(
    stage: DevelopmentStage.helper,
    hintDelay: Duration(seconds: 5),
    maxActiveTargets: 2,
    distractorCount: 1,
    puzzlePieceCount: 3,
    maxCountingNumber: 0,
    routineStepCount: 2,
    usesSequences: false,
    itemScale: 1.1,
  );

  static const StageConfig littleThinker = StageConfig(
    stage: DevelopmentStage.littleThinker,
    hintDelay: Duration(seconds: 7),
    maxActiveTargets: 3,
    distractorCount: 2,
    puzzlePieceCount: 4,
    maxCountingNumber: 3,
    routineStepCount: 5,
    usesSequences: true,
    itemScale: 1.0,
  );

  static StageConfig of(DevelopmentStage stage) => switch (stage) {
        DevelopmentStage.explorer => explorer,
        DevelopmentStage.helper => helper,
        DevelopmentStage.littleThinker => littleThinker,
      };
}
