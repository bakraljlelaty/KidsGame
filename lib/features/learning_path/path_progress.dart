import 'package:flutter/foundation.dart';

import '../../content/path/learning_path.dart';
import '../../core/persistence/json_document.dart';
import '../../core/persistence/local_store.dart';
import '../../shared/game/activity_spec.dart';
import '../../shared/models/age_band.dart';

/// Persisted learning-path progress: completed node keys (per band) and
/// earned unit badges.
class PathProgressData {
  PathProgressData({Set<String>? completedNodeKeys, Set<String>? unitBadges})
      : completedNodeKeys = completedNodeKeys ?? {},
        unitBadges = unitBadges ?? {};

  final Set<String> completedNodeKeys;
  final Set<String> unitBadges;

  Map<String, dynamic> toJson() => {
        'completedNodeKeys': completedNodeKeys.toList(),
        'unitBadges': unitBadges.toList(),
      };

  factory PathProgressData.fromJson(Map<String, dynamic> json) =>
      PathProgressData(
        completedNodeKeys:
            ((json['completedNodeKeys'] as List?)?.cast<String>() ?? [])
                .toSet(),
        unitBadges:
            ((json['unitBadges'] as List?)?.cast<String>() ?? []).toSet(),
      );
}

class PathProgressRepository {
  PathProgressRepository(LocalStore store)
      : _doc = JsonDocument<PathProgressData>(
          store: store,
          storeKey: 'path_progress',
          decode: PathProgressData.fromJson,
          encode: (d) => d.toJson(),
          fallback: PathProgressData.new,
        );

  final JsonDocument<PathProgressData> _doc;

  Future<PathProgressData> load() => _doc.load();
  Future<void> save(PathProgressData data) => _doc.save(data);
  Future<void> clear() => _doc.clear();
}

class PathProgressController extends ChangeNotifier {
  PathProgressController(this._repository);

  final PathProgressRepository _repository;

  PathProgressData _data = PathProgressData();
  PathProgressData get data => _data;

  Future<void> init() async {
    _data = await _repository.load();
    notifyListeners();
  }

  bool isNodeCompleted(AgeBand band, ActivitySpec spec) =>
      _data.completedNodeKeys.contains(LearningPath.nodeKey(band, spec));

  bool hasUnitBadge(PathUnit unit) => _data.unitBadges.contains(unit.id);

  /// A node is playable when every node before it (across units, in path
  /// order) is complete — or it is already complete (free replay).
  bool isNodeUnlocked(AgeBand band, ActivitySpec spec) {
    for (final unit in LearningPath.unitsFor(band)) {
      for (final node in unit.nodes) {
        if (node.id == spec.id) return true;
        if (!isNodeCompleted(band, node)) return false;
      }
    }
    return false;
  }

  /// The next node the child should play on the path (null = path done).
  ActivitySpec? nextNode(AgeBand band) {
    for (final unit in LearningPath.unitsFor(band)) {
      for (final node in unit.nodes) {
        if (!isNodeCompleted(band, node)) return node;
      }
    }
    return null;
  }

  /// Marks a node complete; returns the unit if this completed it (for the
  /// badge celebration), else null.
  Future<PathUnit?> markNodeCompleted(AgeBand band, ActivitySpec spec) async {
    final key = LearningPath.nodeKey(band, spec);
    if (_data.completedNodeKeys.contains(key)) {
      notifyListeners();
      return null;
    }
    _data.completedNodeKeys.add(key);

    PathUnit? newlyCompleted;
    for (final unit in LearningPath.unitsFor(band)) {
      if (unit.nodes.any((n) => n.id == spec.id) &&
          unit.nodes.every((n) => isNodeCompleted(band, n)) &&
          !_data.unitBadges.contains(unit.id)) {
        _data.unitBadges.add(unit.id);
        newlyCompleted = unit;
      }
    }
    notifyListeners();
    await _repository.save(_data);
    return newlyCompleted;
  }

  double unitProgress(AgeBand band, PathUnit unit) {
    if (unit.nodes.isEmpty) return 1;
    final done =
        unit.nodes.where((n) => isNodeCompleted(band, n)).length;
    return done / unit.nodes.length;
  }

  Future<void> reset() async {
    _data = PathProgressData();
    notifyListeners();
    await _repository.save(_data);
  }

  Future<void> reloadFromStore() async {
    _data = await _repository.load();
    notifyListeners();
  }
}
