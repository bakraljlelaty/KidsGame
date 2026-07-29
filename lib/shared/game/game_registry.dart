import '../../features/bedtime_routine/bedtime_routine_game.dart';
import '../../features/bubble_pop/bubble_pop_game.dart';
import '../../features/build_rocket/build_rocket_game.dart';
import '../../features/dancing_socks/dancing_socks_game.dart';
import '../../features/feed_animals/feed_animals_game.dart';
import '../../features/muddy_pig/muddy_pig_game.dart';
import '../../l10n/app_localizations.dart';
import '../models/game_id.dart';
import '../models/skill.dart';
import 'game_context.dart';
import 'toddler_game.dart';

/// Static metadata + factory for one mini-game.
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.skills,
    required this.title,
    required this.create,
  });

  final GameId id;

  /// Skills this game practises (recorded neutrally for parents).
  final List<Skill> skills;

  final String Function(AppLocalizations l10n) title;

  final ToddlerGame Function(GameContext context) create;
}

/// The single source of truth connecting GameIds to implementations.
/// The world map, access settings and mini-game screen all read this.
class GameRegistry {
  GameRegistry._();

  static final Map<GameId, GameDefinition> _games = {
    GameId.feedAnimals: GameDefinition(
      id: GameId.feedAnimals,
      skills: const [
        Skill.animals,
        Skill.matching,
        Skill.dragging,
        Skill.attention,
      ],
      title: (l10n) => l10n.gameFeedAnimals,
      create: FeedAnimalsGame.new,
    ),
    GameId.bubblePop: GameDefinition(
      id: GameId.bubblePop,
      skills: const [
        Skill.tapping,
        Skill.colors,
        Skill.shapes,
        Skill.attention,
      ],
      title: (l10n) => l10n.gameBubblePop,
      create: BubblePopGame.new,
    ),
    GameId.dancingSocks: GameDefinition(
      id: GameId.dancingSocks,
      skills: const [Skill.matching, Skill.dragging, Skill.colors],
      title: (l10n) => l10n.gameDancingSocks,
      create: DancingSocksGame.new,
    ),
    GameId.muddyPig: GameDefinition(
      id: GameId.muddyPig,
      skills: const [Skill.swiping, Skill.sequencing, Skill.routines],
      title: (l10n) => l10n.gameMuddyPig,
      create: MuddyPigGame.new,
    ),
    GameId.buildRocket: GameDefinition(
      id: GameId.buildRocket,
      skills: const [
        Skill.shapes,
        Skill.spatial,
        Skill.fineMotor,
        Skill.dragging,
      ],
      title: (l10n) => l10n.gameBuildRocket,
      create: BuildRocketGame.new,
    ),
    GameId.bedtimeRoutine: GameDefinition(
      id: GameId.bedtimeRoutine,
      skills: const [
        Skill.routines,
        Skill.sequencing,
        Skill.dragging,
        Skill.tapping,
      ],
      title: (l10n) => l10n.gameBedtimeRoutine,
      create: BedtimeRoutineGame.new,
    ),
  };

  static GameDefinition of(GameId id) => _games[id]!;

  static List<GameDefinition> get all =>
      [for (final id in GameId.values) _games[id]!];
}
