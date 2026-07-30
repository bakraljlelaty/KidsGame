import '../shared/game/activity_spec.dart';
import '../shared/models/age_band.dart';
import '../shared/models/game_id.dart';
import '../shared/models/skill.dart';
import '../shared/models/subject.dart';

/// The academy's activity catalog: 5–8 activities per concept area,
/// instantiated from the reusable engines. Difficulty comes from the age
/// band at runtime; `params` only select engine modes.
///
/// Node ids are persisted in path progress — keep them stable.
class ActivityDefinitions {
  ActivityDefinitions._();

  static const List<ActivitySpec> colors = [
    ActivitySpec(
        id: 'colors_find', engine: ActivityEngine.tapChoice,
        subject: Subject.colors, contentPack: 'colors',
        skills: [Skill.colors, Skill.tapping, Skill.attention]),
    ActivitySpec(
        id: 'colors_odd', engine: ActivityEngine.tapChoice,
        subject: Subject.colors, contentPack: 'colors',
        params: {'oddOneOut': 1},
        skills: [Skill.colors, Skill.attention]),
    ActivitySpec(
        id: 'colors_sort', engine: ActivityEngine.dragSort,
        subject: Subject.colors, contentPack: 'colors',
        skills: [Skill.colors, Skill.matching, Skill.dragging]),
    ActivitySpec(
        id: 'colors_memory', engine: ActivityEngine.memoryPairs,
        subject: Subject.colors, contentPack: 'colors',
        skills: [Skill.colors, Skill.memory, Skill.attention]),
    ActivitySpec(
        id: 'colors_pattern', engine: ActivityEngine.patternComplete,
        subject: Subject.colors, contentPack: 'colors',
        skills: [Skill.colors, Skill.patterns]),
    ActivitySpec(
        id: 'colors_count', engine: ActivityEngine.countAndGive,
        subject: Subject.colors, contentPack: 'colors',
        skills: [Skill.colors, Skill.counting, Skill.dragging]),
  ];

  static const List<ActivitySpec> shapes = [
    ActivitySpec(
        id: 'shapes_find', engine: ActivityEngine.tapChoice,
        subject: Subject.shapes, contentPack: 'shapes',
        skills: [Skill.shapes, Skill.tapping, Skill.attention]),
    ActivitySpec(
        id: 'shapes_odd', engine: ActivityEngine.tapChoice,
        subject: Subject.shapes, contentPack: 'shapes',
        params: {'oddOneOut': 1},
        skills: [Skill.shapes, Skill.attention]),
    ActivitySpec(
        id: 'shapes_shadow', engine: ActivityEngine.shadowMatch,
        subject: Subject.shapes, contentPack: 'shapes',
        skills: [Skill.shapes, Skill.matching, Skill.dragging]),
    ActivitySpec(
        id: 'shapes_sort', engine: ActivityEngine.dragSort,
        subject: Subject.shapes, contentPack: 'shapes',
        skills: [Skill.shapes, Skill.matching, Skill.dragging]),
    ActivitySpec(
        id: 'shapes_memory', engine: ActivityEngine.memoryPairs,
        subject: Subject.shapes, contentPack: 'shapes',
        skills: [Skill.shapes, Skill.memory]),
    ActivitySpec(
        id: 'shapes_pattern', engine: ActivityEngine.patternComplete,
        subject: Subject.shapes, contentPack: 'shapes',
        skills: [Skill.shapes, Skill.patterns]),
    ActivitySpec(
        id: 'shapes_trace', engine: ActivityEngine.traceShape,
        subject: Subject.shapes, contentPack: 'shapes',
        skills: [Skill.shapes, Skill.fineMotor]),
  ];

  static const List<ActivitySpec> animals = [
    ActivitySpec(
        id: 'animals_find', engine: ActivityEngine.tapChoice,
        subject: Subject.animals, contentPack: 'animals',
        skills: [Skill.animals, Skill.tapping, Skill.attention]),
    ActivitySpec(
        id: 'animals_odd', engine: ActivityEngine.tapChoice,
        subject: Subject.animals, contentPack: 'animals',
        params: {'oddOneOut': 1},
        skills: [Skill.animals, Skill.attention]),
    ActivitySpec(
        id: 'animals_shadow', engine: ActivityEngine.shadowMatch,
        subject: Subject.animals, contentPack: 'animals',
        skills: [Skill.animals, Skill.matching, Skill.dragging]),
    ActivitySpec(
        id: 'animals_sort', engine: ActivityEngine.dragSort,
        subject: Subject.animals, contentPack: 'animals',
        skills: [Skill.animals, Skill.matching]),
    ActivitySpec(
        id: 'animals_memory', engine: ActivityEngine.memoryPairs,
        subject: Subject.animals, contentPack: 'animals',
        skills: [Skill.animals, Skill.memory]),
    ActivitySpec(
        id: 'animals_pattern', engine: ActivityEngine.patternComplete,
        subject: Subject.animals, contentPack: 'animals',
        skills: [Skill.animals, Skill.patterns]),
    ActivitySpec(
        id: 'animals_count', engine: ActivityEngine.countAndGive,
        subject: Subject.animals, contentPack: 'animals',
        skills: [Skill.animals, Skill.counting]),
  ];

  static const List<ActivitySpec> food = [
    ActivitySpec(
        id: 'food_find', engine: ActivityEngine.tapChoice,
        subject: Subject.food, contentPack: 'food',
        skills: [Skill.matching, Skill.tapping, Skill.attention]),
    ActivitySpec(
        id: 'food_odd', engine: ActivityEngine.tapChoice,
        subject: Subject.food, contentPack: 'food',
        params: {'oddOneOut': 1},
        skills: [Skill.attention]),
    ActivitySpec(
        id: 'food_shadow', engine: ActivityEngine.shadowMatch,
        subject: Subject.food, contentPack: 'food',
        skills: [Skill.matching, Skill.dragging]),
    ActivitySpec(
        id: 'food_sort', engine: ActivityEngine.dragSort,
        subject: Subject.food, contentPack: 'food',
        skills: [Skill.matching, Skill.dragging]),
    ActivitySpec(
        id: 'food_memory', engine: ActivityEngine.memoryPairs,
        subject: Subject.food, contentPack: 'food',
        skills: [Skill.memory, Skill.attention]),
    ActivitySpec(
        id: 'food_pattern', engine: ActivityEngine.patternComplete,
        subject: Subject.food, contentPack: 'food',
        skills: [Skill.patterns]),
    ActivitySpec(
        id: 'food_count', engine: ActivityEngine.countAndGive,
        subject: Subject.food, contentPack: 'food',
        skills: [Skill.counting, Skill.dragging]),
  ];

  static const List<ActivitySpec> numbers = [
    ActivitySpec(
        id: 'numbers_find', engine: ActivityEngine.tapChoice,
        subject: Subject.numbers, contentPack: 'numbers',
        skills: [Skill.counting, Skill.tapping]),
    ActivitySpec(
        id: 'numbers_how_many', engine: ActivityEngine.tapChoice,
        subject: Subject.numbers, contentPack: 'numbers',
        params: {'countMode': 1},
        skills: [Skill.counting, Skill.attention]),
    ActivitySpec(
        id: 'numbers_give', engine: ActivityEngine.countAndGive,
        subject: Subject.numbers, contentPack: 'food',
        skills: [Skill.counting, Skill.dragging]),
    ActivitySpec(
        id: 'numbers_memory', engine: ActivityEngine.memoryPairs,
        subject: Subject.numbers, contentPack: 'numbers',
        skills: [Skill.counting, Skill.memory]),
    ActivitySpec(
        id: 'numbers_pattern', engine: ActivityEngine.patternComplete,
        subject: Subject.numbers, contentPack: 'numbers',
        skills: [Skill.counting, Skill.patterns]),
    ActivitySpec(
        id: 'numbers_trace', engine: ActivityEngine.traceShape,
        subject: Subject.numbers, contentPack: 'numbers',
        skills: [Skill.counting, Skill.fineMotor]),
  ];

  /// Letter activities use the language-appropriate alphabet at runtime
  /// (contentPack 'letters' resolves via ItemCatalog.lettersFor).
  static const List<ActivitySpec> letters = [
    ActivitySpec(
        id: 'letters_find', engine: ActivityEngine.tapChoice,
        subject: Subject.letters, contentPack: 'letters',
        skills: [Skill.tapping, Skill.attention]),
    ActivitySpec(
        id: 'letters_odd', engine: ActivityEngine.tapChoice,
        subject: Subject.letters, contentPack: 'letters',
        params: {'oddOneOut': 1},
        skills: [Skill.attention]),
    ActivitySpec(
        id: 'letters_shadow', engine: ActivityEngine.shadowMatch,
        subject: Subject.letters, contentPack: 'letters',
        skills: [Skill.matching, Skill.dragging]),
    ActivitySpec(
        id: 'letters_memory', engine: ActivityEngine.memoryPairs,
        subject: Subject.letters, contentPack: 'letters',
        skills: [Skill.memory, Skill.attention]),
    ActivitySpec(
        id: 'letters_trace', engine: ActivityEngine.traceShape,
        subject: Subject.letters, contentPack: 'letters',
        skills: [Skill.fineMotor]),
  ];

  /// Open-ended creativity: finger painting and picture stamps.
  /// Participation is the only goal — the big star finishes a picture.
  static const List<ActivitySpec> art = [
    ActivitySpec(
        id: 'art_paint', engine: ActivityEngine.freePaint,
        subject: Subject.art, contentPack: 'colors',
        skills: [Skill.fineMotor, Skill.colors]),
    ActivitySpec(
        id: 'art_stamps_animals', engine: ActivityEngine.freePaint,
        subject: Subject.art, contentPack: 'animals',
        params: {'stamps': 1},
        skills: [Skill.fineMotor, Skill.animals]),
    ActivitySpec(
        id: 'art_stamps_shapes', engine: ActivityEngine.freePaint,
        subject: Subject.art, contentPack: 'shapes',
        params: {'stamps': 1},
        skills: [Skill.fineMotor, Skill.shapes]),
    ActivitySpec(
        id: 'art_stamps_food', engine: ActivityEngine.freePaint,
        subject: Subject.art, contentPack: 'food',
        params: {'stamps': 1},
        skills: [Skill.fineMotor]),
    ActivitySpec(
        id: 'art_trace_shapes', engine: ActivityEngine.traceShape,
        subject: Subject.art, contentPack: 'shapes',
        skills: [Skill.fineMotor, Skill.shapes]),
  ];

  /// The six bespoke v1 mini-games as path/room nodes.
  static const List<ActivitySpec> milosWorld = [
    ActivitySpec(
        id: 'mw_feed_animals', engine: ActivityEngine.bespoke,
        subject: Subject.milosWorld, bespokeGame: GameId.feedAnimals,
        skills: [Skill.animals, Skill.matching, Skill.dragging]),
    ActivitySpec(
        id: 'mw_bubble_pop', engine: ActivityEngine.bespoke,
        subject: Subject.milosWorld, bespokeGame: GameId.bubblePop,
        skills: [Skill.tapping, Skill.colors, Skill.attention]),
    ActivitySpec(
        id: 'mw_dancing_socks', engine: ActivityEngine.bespoke,
        subject: Subject.milosWorld, bespokeGame: GameId.dancingSocks,
        skills: [Skill.matching, Skill.dragging]),
    ActivitySpec(
        id: 'mw_muddy_pig', engine: ActivityEngine.bespoke,
        subject: Subject.milosWorld, bespokeGame: GameId.muddyPig,
        skills: [Skill.swiping, Skill.routines]),
    ActivitySpec(
        id: 'mw_build_rocket', engine: ActivityEngine.bespoke,
        subject: Subject.milosWorld, bespokeGame: GameId.buildRocket,
        skills: [Skill.shapes, Skill.spatial, Skill.fineMotor]),
    ActivitySpec(
        id: 'mw_bedtime', engine: ActivityEngine.bespoke,
        subject: Subject.milosWorld, bespokeGame: GameId.bedtimeRoutine,
        skills: [Skill.routines, Skill.sequencing]),
  ];

  static List<ActivitySpec> forSubject(Subject subject) => switch (subject) {
        Subject.colors => colors,
        Subject.shapes => shapes,
        Subject.animals => animals,
        Subject.food => food,
        Subject.numbers => numbers,
        Subject.letters => letters,
        Subject.art => art,
        Subject.milosWorld => milosWorld,
      };

  /// Subjects available in a band (letters wait for bands that enable them).
  static List<Subject> subjectsFor(AgeBand band) => [
        Subject.colors,
        Subject.shapes,
        Subject.animals,
        Subject.food,
        Subject.numbers,
        if (BandConfig.of(band).lettersEnabled) Subject.letters,
        Subject.art,
        Subject.milosWorld,
      ];

  static ActivitySpec? byId(String id) {
    for (final subject in Subject.values) {
      for (final spec in forSubject(subject)) {
        if (spec.id == id) return spec;
      }
    }
    return null;
  }
}
