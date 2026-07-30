import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/content/activity_definitions.dart';
import 'package:little_wonder_world/content/items/item_catalog.dart';
import 'package:little_wonder_world/shared/game/activity_spec.dart';
import 'package:little_wonder_world/shared/models/age_band.dart';
import 'package:little_wonder_world/shared/models/subject.dart';

void main() {
  group('ActivityDefinitions catalog', () {
    test('every subject except milosWorld offers 5-8 activities', () {
      for (final subject in Subject.values) {
        if (subject == Subject.milosWorld) continue;
        final specs = ActivityDefinitions.forSubject(subject);
        expect(specs.length, inInclusiveRange(5, 8),
            reason: '${subject.storageKey} must offer 5-8 activities');
      }
    });

    test('all spec ids are globally unique', () {
      final seen = <String>{};
      for (final subject in Subject.values) {
        for (final spec in ActivityDefinitions.forSubject(subject)) {
          expect(seen.add(spec.id), isTrue,
              reason: 'duplicate spec id ${spec.id}');
        }
      }
    });

    test('every spec is filed under its own subject', () {
      for (final subject in Subject.values) {
        for (final spec in ActivityDefinitions.forSubject(subject)) {
          expect(spec.subject, subject);
        }
      }
    });

    test(
        "every referenced contentPack exists in ItemCatalog.packs or is the "
        "language-resolved 'letters'", () {
      for (final subject in Subject.values) {
        for (final spec in ActivityDefinitions.forSubject(subject)) {
          if (spec.engine == ActivityEngine.bespoke) continue;
          expect(spec.contentPack, isNotEmpty,
              reason: '${spec.id} must name a content pack');
          expect(
            ItemCatalog.packs.containsKey(spec.contentPack) ||
                spec.contentPack == 'letters',
            isTrue,
            reason:
                "${spec.id} references unknown pack '${spec.contentPack}'",
          );
        }
      }
    });

    test('bespoke specs live only in milosWorld and always name their game',
        () {
      for (final subject in Subject.values) {
        for (final spec in ActivityDefinitions.forSubject(subject)) {
          if (spec.engine == ActivityEngine.bespoke) {
            expect(subject, Subject.milosWorld,
                reason: '${spec.id} is bespoke but not in milosWorld');
            expect(spec.bespokeGame, isNotNull,
                reason: '${spec.id} must set bespokeGame');
          } else {
            expect(spec.bespokeGame, isNull,
                reason: '${spec.id} is engine-based, bespokeGame must be null');
          }
        }
      }
      // And every Milo's World node is bespoke.
      for (final spec in ActivityDefinitions.milosWorld) {
        expect(spec.engine, ActivityEngine.bespoke);
      }
    });

    test('subjectsFor gates letters by band', () {
      final youngest = ActivityDefinitions.subjectsFor(AgeBand.twoToThree);
      expect(youngest, isNot(contains(Subject.letters)));

      final oldest = ActivityDefinitions.subjectsFor(AgeBand.fiveToSix);
      expect(oldest, contains(Subject.letters));
    });

    test('byId resolves every id in the catalog', () {
      for (final subject in Subject.values) {
        for (final spec in ActivityDefinitions.forSubject(subject)) {
          expect(ActivityDefinitions.byId(spec.id), same(spec),
              reason: 'byId must resolve ${spec.id}');
        }
      }
      expect(ActivityDefinitions.byId('no_such_activity'), isNull);
    });
  });
}
