import '../../shared/game/activity_spec.dart';
import '../../shared/models/age_band.dart';
import '../../shared/models/subject.dart';
import '../activity_definitions.dart';

/// One unit of the guided learning path (a themed group of nodes).
class PathUnit {
  const PathUnit({
    required this.id,
    required this.subject,
    required this.nodes,
  });

  final String id;
  final Subject subject;
  final List<ActivitySpec> nodes;
}

/// The guided path: one unit per concept area, ordered gently from colors
/// to letters, ending in Milo's World. Content repeats across bands at the
/// band's own difficulty, so moving up feels familiar but deeper.
class LearningPath {
  LearningPath._();

  static List<PathUnit> unitsFor(AgeBand band) => [
        for (final subject in ActivityDefinitions.subjectsFor(band))
          PathUnit(
            id: '${band.storageKey}_${subject.storageKey}',
            subject: subject,
            nodes: ActivityDefinitions.forSubject(subject),
          ),
      ];

  /// Progress key for one node in one band.
  static String nodeKey(AgeBand band, ActivitySpec spec) =>
      '${band.storageKey}/${spec.id}';
}
