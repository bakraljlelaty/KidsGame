import 'development_stage.dart';

/// The four parent-selectable age bands of the academy (v2). Bands tune
/// every activity engine; the v1 [DevelopmentStage] survives only as a
/// derived value for the six bespoke mini-games.
enum AgeBand {
  twoToThree('two_three'),
  threeToFour('three_four'),
  fourToFive('four_five'),
  fiveToSix('five_six');

  const AgeBand(this.storageKey);

  final String storageKey;

  static AgeBand fromStorageKey(String? key) {
    for (final band in AgeBand.values) {
      if (band.storageKey == key) return band;
    }
    return AgeBand.twoToThree;
  }

  /// v1 stage equivalent used by the six bespoke mini-games.
  DevelopmentStage get legacyStage => switch (this) {
        AgeBand.twoToThree => DevelopmentStage.explorer,
        AgeBand.threeToFour => DevelopmentStage.helper,
        AgeBand.fourToFive => DevelopmentStage.littleThinker,
        AgeBand.fiveToSix => DevelopmentStage.littleThinker,
      };

  /// Band a v1 stage migrates to (schema v1 -> v2).
  static AgeBand fromLegacyStage(DevelopmentStage stage) => switch (stage) {
        DevelopmentStage.explorer => AgeBand.twoToThree,
        DevelopmentStage.helper => AgeBand.threeToFour,
        DevelopmentStage.littleThinker => AgeBand.fourToFive,
      };

  AgeBand? get next => switch (this) {
        AgeBand.twoToThree => AgeBand.threeToFour,
        AgeBand.threeToFour => AgeBand.fourToFive,
        AgeBand.fourToFive => AgeBand.fiveToSix,
        AgeBand.fiveToSix => null,
      };
}

/// Difficulty and content tuning for one age band. Activity engines read
/// these instead of branching on the band enum; per-node `params` in the
/// learning path may override individual values.
class BandConfig {
  const BandConfig({
    required this.band,
    required this.hintDelay,
    required this.choiceCount,
    required this.memoryPairCount,
    required this.patternLength,
    required this.patternChoices,
    required this.countingMax,
    required this.sortBinCount,
    required this.sortItemCount,
    required this.itemScale,
    required this.lettersEnabled,
    required this.traceDetail,
  });

  final AgeBand band;

  /// Idle time before the automatic hint appears.
  final Duration hintDelay;

  /// Options shown by choice-style engines (correct one + distractors).
  final int choiceCount;

  /// Pairs on the memory board.
  final int memoryPairCount;

  /// Length of the visible pattern before the gap (AB=2, ABC=3, AABB=4).
  final int patternLength;

  /// Answer options offered by PatternComplete.
  final int patternChoices;

  /// Highest quantity used by counting activities.
  final int countingMax;

  /// Bins and items for DragSort.
  final int sortBinCount;
  final int sortItemCount;

  /// Relative size multiplier for interactive objects.
  final double itemScale;

  /// Whether letter activities appear at all in this band.
  final bool lettersEnabled;

  /// Trace path complexity: 1 = big simple shapes, 2 = + letters/numbers,
  /// 3 = finer letter forms.
  final int traceDetail;

  static const BandConfig twoToThree = BandConfig(
    band: AgeBand.twoToThree,
    hintDelay: Duration(seconds: 3),
    choiceCount: 2,
    memoryPairCount: 2,
    patternLength: 2,
    patternChoices: 2,
    countingMax: 3,
    sortBinCount: 2,
    sortItemCount: 4,
    itemScale: 1.25,
    lettersEnabled: false,
    traceDetail: 1,
  );

  static const BandConfig threeToFour = BandConfig(
    band: AgeBand.threeToFour,
    hintDelay: Duration(seconds: 5),
    choiceCount: 3,
    memoryPairCount: 3,
    patternLength: 2,
    patternChoices: 3,
    countingMax: 5,
    sortBinCount: 2,
    sortItemCount: 6,
    itemScale: 1.1,
    lettersEnabled: true,
    traceDetail: 1,
  );

  static const BandConfig fourToFive = BandConfig(
    band: AgeBand.fourToFive,
    hintDelay: Duration(seconds: 6),
    choiceCount: 4,
    memoryPairCount: 4,
    patternLength: 3,
    patternChoices: 3,
    countingMax: 7,
    sortBinCount: 3,
    sortItemCount: 6,
    itemScale: 1.0,
    lettersEnabled: true,
    traceDetail: 2,
  );

  static const BandConfig fiveToSix = BandConfig(
    band: AgeBand.fiveToSix,
    hintDelay: Duration(seconds: 7),
    choiceCount: 4,
    memoryPairCount: 6,
    patternLength: 4,
    patternChoices: 4,
    countingMax: 10,
    sortBinCount: 3,
    sortItemCount: 9,
    itemScale: 0.95,
    lettersEnabled: true,
    traceDetail: 3,
  );

  static BandConfig of(AgeBand band) => switch (band) {
        AgeBand.twoToThree => twoToThree,
        AgeBand.threeToFour => threeToFour,
        AgeBand.fourToFive => fourToFive,
        AgeBand.fiveToSix => fiveToSix,
      };
}
