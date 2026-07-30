import '../../features/activities/count_and_give/count_and_give_game.dart';
import '../../features/activities/drag_sort/drag_sort_game.dart';
import '../../features/activities/memory_pairs/memory_pairs_game.dart';
import '../../features/activities/pattern_complete/pattern_complete_game.dart';
import '../../features/activities/shadow_match/shadow_match_game.dart';
import '../../features/activities/tap_choice/tap_choice_game.dart';
import '../../features/activities/trace_shape/trace_shape_game.dart';
import 'activity_spec.dart';
import 'game_context.dart';
import 'game_registry.dart';
import 'toddler_game.dart';

/// Creates the right game for an ActivitySpec (engine or bespoke).
class ActivityRegistry {
  ActivityRegistry._();

  static ToddlerGame create(ActivitySpec spec, GameContext context) =>
      switch (spec.engine) {
        ActivityEngine.tapChoice => TapChoiceGame(context),
        ActivityEngine.dragSort => DragSortGame(context),
        ActivityEngine.shadowMatch => ShadowMatchGame(context),
        ActivityEngine.memoryPairs => MemoryPairsGame(context),
        ActivityEngine.patternComplete => PatternCompleteGame(context),
        ActivityEngine.countAndGive => CountAndGiveGame(context),
        ActivityEngine.traceShape => TraceShapeGame(context),
        ActivityEngine.bespoke =>
          GameRegistry.of(spec.bespokeGame!).create(context),
      };
}
