import '../../core/persistence/json_document.dart';
import '../../core/persistence/local_store.dart';

/// One sticker placed on a sticker-book scene, in scene-relative
/// coordinates (0..1 so placements survive screen-size changes).
class StickerPlacement {
  const StickerPlacement({
    required this.stickerId,
    required this.sceneId,
    required this.x,
    required this.y,
  });

  final String stickerId;
  final String sceneId;
  final double x;
  final double y;

  StickerPlacement moved(double newX, double newY) => StickerPlacement(
        stickerId: stickerId,
        sceneId: sceneId,
        x: newX,
        y: newY,
      );

  Map<String, dynamic> toJson() => {
        'stickerId': stickerId,
        'sceneId': sceneId,
        'x': x,
        'y': y,
      };

  factory StickerPlacement.fromJson(Map<String, dynamic> json) =>
      StickerPlacement(
        stickerId: json['stickerId'] as String? ?? '',
        sceneId: json['sceneId'] as String? ?? '',
        x: (json['x'] as num?)?.toDouble() ?? 0.5,
        y: (json['y'] as num?)?.toDouble() ?? 0.5,
      );
}

class StickerBookData {
  StickerBookData({List<StickerPlacement>? placements})
      : placements = placements ?? [];

  final List<StickerPlacement> placements;

  List<StickerPlacement> forScene(String sceneId) =>
      placements.where((p) => p.sceneId == sceneId).toList(growable: false);

  Map<String, dynamic> toJson() => {
        'placements': placements.map((p) => p.toJson()).toList(),
      };

  factory StickerBookData.fromJson(Map<String, dynamic> json) =>
      StickerBookData(
        placements: [
          for (final raw in (json['placements'] as List?) ?? [])
            StickerPlacement.fromJson((raw as Map).cast<String, dynamic>()),
        ],
      );
}

class StickerBookRepository {
  StickerBookRepository(LocalStore store)
      : _doc = JsonDocument<StickerBookData>(
          store: store,
          storeKey: 'sticker_book',
          decode: StickerBookData.fromJson,
          encode: (d) => d.toJson(),
          fallback: StickerBookData.new,
        );

  final JsonDocument<StickerBookData> _doc;

  Future<StickerBookData> load() => _doc.load();
  Future<void> save(StickerBookData data) => _doc.save(data);
  Future<void> clear() => _doc.clear();
}
