import '../../core/persistence/json_document.dart';
import '../../core/persistence/local_store.dart';
import '../../shared/models/game_id.dart';

/// How the child moves between games.
enum PlayMode {
  free('free'),
  guided('guided');

  const PlayMode(this.storageKey);
  final String storageKey;

  static PlayMode fromStorageKey(String? key) =>
      key == PlayMode.guided.storageKey ? PlayMode.guided : PlayMode.free;
}

/// Which games are available on the world map and in what order.
class GameAccess {
  GameAccess({
    Map<GameId, bool>? enabled,
    this.playMode = PlayMode.free,
    List<GameId>? guidedOrder,
  })  : enabled = {
          for (final id in GameId.values) id: enabled?[id] ?? true,
        },
        guidedOrder = guidedOrder ?? List.of(GameId.values);

  final Map<GameId, bool> enabled;
  final PlayMode playMode;

  /// Order used when [playMode] is guided.
  final List<GameId> guidedOrder;

  bool isEnabled(GameId id) => enabled[id] ?? true;

  List<GameId> get enabledGames =>
      GameId.values.where(isEnabled).toList(growable: false);

  GameAccess copyWith({
    Map<GameId, bool>? enabled,
    PlayMode? playMode,
    List<GameId>? guidedOrder,
  }) =>
      GameAccess(
        enabled: enabled ?? this.enabled,
        playMode: playMode ?? this.playMode,
        guidedOrder: guidedOrder ?? this.guidedOrder,
      );

  GameAccess withGameEnabled(GameId id, bool value) =>
      copyWith(enabled: {...enabled, id: value});

  Map<String, dynamic> toJson() => {
        'enabled': {
          for (final e in enabled.entries) e.key.storageKey: e.value,
        },
        'playMode': playMode.storageKey,
        'guidedOrder': guidedOrder.map((g) => g.storageKey).toList(),
      };

  factory GameAccess.fromJson(Map<String, dynamic> json) {
    final enabledRaw = (json['enabled'] as Map?)?.cast<String, dynamic>() ?? {};
    final orderRaw = (json['guidedOrder'] as List?)?.cast<String>() ?? [];
    final order = <GameId>[
      for (final key in orderRaw)
        if (GameId.fromStorageKey(key) != null) GameId.fromStorageKey(key)!,
    ];
    for (final id in GameId.values) {
      if (!order.contains(id)) order.add(id);
    }
    return GameAccess(
      enabled: {
        for (final id in GameId.values)
          id: enabledRaw[id.storageKey] as bool? ?? true,
      },
      playMode: PlayMode.fromStorageKey(json['playMode'] as String?),
      guidedOrder: order,
    );
  }
}

class GameAccessRepository {
  GameAccessRepository(LocalStore store)
      : _doc = JsonDocument<GameAccess>(
          store: store,
          storeKey: 'game_access',
          decode: GameAccess.fromJson,
          encode: (a) => a.toJson(),
          fallback: GameAccess.new,
        );

  final JsonDocument<GameAccess> _doc;

  Future<GameAccess> load() => _doc.load();
  Future<void> save(GameAccess access) => _doc.save(access);
  Future<void> clear() => _doc.clear();
}
