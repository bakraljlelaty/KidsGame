import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/content/path/learning_path.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';
import 'package:little_wonder_world/features/learning_path/path_progress.dart';
import 'package:little_wonder_world/shared/models/age_band.dart';

Future<PathProgressController> newController(InMemoryStore store) async {
  final controller = PathProgressController(PathProgressRepository(store));
  await controller.init();
  return controller;
}

void main() {
  const band = AgeBand.twoToThree;

  group('PathProgressController', () {
    test('initially only the very first node of the first unit is unlocked',
        () async {
      final controller = await newController(InMemoryStore());
      final units = LearningPath.unitsFor(band);

      expect(controller.isNodeUnlocked(band, units[0].nodes[0]), isTrue);
      expect(controller.isNodeUnlocked(band, units[0].nodes[1]), isFalse);
      // Every unit is open from the start (nodes gate only within a unit).
      expect(controller.isNodeUnlocked(band, units[1].nodes[0]), isTrue);
      expect(controller.isNodeUnlocked(band, units[1].nodes[1]), isFalse);
      expect(controller.nextNode(band), same(units[0].nodes[0]));
    });

    test('completing nodes in order unlocks the next one', () async {
      final controller = await newController(InMemoryStore());
      final unit = LearningPath.unitsFor(band).first;

      await controller.markNodeCompleted(band, unit.nodes[0]);
      expect(controller.isNodeCompleted(band, unit.nodes[0]), isTrue);
      expect(controller.isNodeUnlocked(band, unit.nodes[1]), isTrue);
      expect(controller.isNodeUnlocked(band, unit.nodes[2]), isFalse);
      expect(controller.nextNode(band), same(unit.nodes[1]));

      await controller.markNodeCompleted(band, unit.nodes[1]);
      expect(controller.isNodeUnlocked(band, unit.nodes[2]), isTrue);
      expect(controller.nextNode(band), same(unit.nodes[2]));
    });

    test(
        'markNodeCompleted returns the unit exactly when its last node '
        'completes, and null on a re-completion', () async {
      final controller = await newController(InMemoryStore());
      final units = LearningPath.unitsFor(band);
      final unit = units.first;

      for (var i = 0; i < unit.nodes.length - 1; i++) {
        final completed = await controller.markNodeCompleted(
            band, unit.nodes[i]);
        expect(completed, isNull,
            reason: 'node $i is not the last of the unit');
        expect(controller.hasUnitBadge(unit), isFalse);
      }

      final completed =
          await controller.markNodeCompleted(band, unit.nodes.last);
      expect(completed, isNotNull);
      expect(completed!.id, unit.id);
      expect(controller.hasUnitBadge(unit), isTrue);

      // Re-completing the same node awards nothing new.
      final again =
          await controller.markNodeCompleted(band, unit.nodes.last);
      expect(again, isNull);
      expect(controller.hasUnitBadge(unit), isTrue);

      // The path now points into the second unit.
      expect(controller.nextNode(band), same(units[1].nodes[0]));
      expect(controller.isNodeUnlocked(band, units[1].nodes[0]), isTrue);
    });

    test('progress persists across a new controller on the same store',
        () async {
      final store = InMemoryStore();
      final first = await newController(store);
      final unit = LearningPath.unitsFor(band).first;

      for (final node in unit.nodes) {
        await first.markNodeCompleted(band, node);
      }
      expect(first.hasUnitBadge(unit), isTrue);

      final second = await newController(store);
      for (final node in unit.nodes) {
        expect(second.isNodeCompleted(band, node), isTrue);
      }
      expect(second.hasUnitBadge(unit), isTrue);
      expect(second.nextNode(band),
          same(LearningPath.unitsFor(band)[1].nodes[0]));
    });

    test('completion is tracked per band', () async {
      final controller = await newController(InMemoryStore());
      final node = LearningPath.unitsFor(band).first.nodes.first;

      await controller.markNodeCompleted(band, node);
      expect(controller.isNodeCompleted(band, node), isTrue);

      // The same activity in the next band is untouched and its path fresh.
      const otherBand = AgeBand.threeToFour;
      expect(controller.isNodeCompleted(otherBand, node), isFalse);
      final otherUnits = LearningPath.unitsFor(otherBand);
      expect(controller.isNodeUnlocked(otherBand, otherUnits[0].nodes[0]),
          isTrue);
      expect(controller.isNodeUnlocked(otherBand, otherUnits[0].nodes[1]),
          isFalse);
      expect(controller.nextNode(otherBand), same(otherUnits[0].nodes[0]));
    });

    test('unitProgress reports the completed fraction', () async {
      final controller = await newController(InMemoryStore());
      final unit = LearningPath.unitsFor(band).first;

      expect(controller.unitProgress(band, unit), 0);

      await controller.markNodeCompleted(band, unit.nodes[0]);
      await controller.markNodeCompleted(band, unit.nodes[1]);
      expect(controller.unitProgress(band, unit),
          closeTo(2 / unit.nodes.length, 1e-9));

      for (final node in unit.nodes) {
        await controller.markNodeCompleted(band, node);
      }
      expect(controller.unitProgress(band, unit), 1);
    });

    test('reset clears completions and badges, persistently', () async {
      final store = InMemoryStore();
      final controller = await newController(store);
      final unit = LearningPath.unitsFor(band).first;

      for (final node in unit.nodes) {
        await controller.markNodeCompleted(band, node);
      }
      expect(controller.hasUnitBadge(unit), isTrue);

      await controller.reset();
      expect(controller.data.completedNodeKeys, isEmpty);
      expect(controller.data.unitBadges, isEmpty);
      expect(controller.hasUnitBadge(unit), isFalse);
      expect(controller.nextNode(band), same(unit.nodes[0]));

      final reloaded = await newController(store);
      expect(reloaded.data.completedNodeKeys, isEmpty);
      expect(reloaded.data.unitBadges, isEmpty);
    });
  });
}
