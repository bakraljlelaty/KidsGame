import '../models/game_id.dart';
import '../models/skill.dart';
import '../models/subject.dart';

/// The seven reusable activity engines plus the six bespoke v1 games.
enum ActivityEngine {
  tapChoice('tap_choice'),
  dragSort('drag_sort'),
  shadowMatch('shadow_match'),
  memoryPairs('memory_pairs'),
  patternComplete('pattern_complete'),
  countAndGive('count_and_give'),
  traceShape('trace_shape'),
  freePaint('free_paint'),
  bespoke('bespoke');

  const ActivityEngine(this.storageKey);

  final String storageKey;
}

/// One playable activity: an engine plus the content it runs on.
///
/// Specs are pure data — they live in the learning-path definitions
/// (lib/content/path/) and in the play-room listings. The [id] is persisted
/// in path progress, so treat it as stable once shipped.
class ActivitySpec {
  const ActivitySpec({
    required this.id,
    required this.engine,
    required this.subject,
    required this.skills,
    this.contentPack = '',
    this.bespokeGame,
    this.params = const {},
  });

  /// Stable unique id, e.g. 'b1_u1_n3_tap_colors'.
  final String id;

  final ActivityEngine engine;
  final Subject subject;

  /// Skills recorded (neutrally) when this activity completes.
  final List<Skill> skills;

  /// ItemCatalog pack the engine draws content from (engine-specific
  /// interpretation; empty for bespoke).
  final String contentPack;

  /// Set when [engine] == ActivityEngine.bespoke.
  final GameId? bespokeGame;

  /// Per-node difficulty overrides applied on top of the band config.
  /// Understood keys (engines ignore what they don't use):
  ///   'choices', 'pairs', 'patternLength', 'patternChoices', 'countMax',
  ///   'bins', 'items', 'rounds', 'traceDetail'.
  final Map<String, int> params;

  int paramOr(String key, int fallback) => params[key] ?? fallback;
}
