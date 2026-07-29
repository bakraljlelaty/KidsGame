import 'package:flutter/foundation.dart';

import 'sticker_placements.dart';

/// Sticker-book scenes the child can decorate.
class StickerScene {
  const StickerScene({required this.id});

  final String id;

  static const meadow = StickerScene(id: 'meadow');
  static const sky = StickerScene(id: 'sky');
  static const sea = StickerScene(id: 'sea');

  static const all = [meadow, sky, sea];
}

class StickerBookController extends ChangeNotifier {
  StickerBookController(this._repository);

  final StickerBookRepository _repository;

  StickerBookData _data = StickerBookData();
  StickerBookData get data => _data;

  Future<void> init() async {
    _data = await _repository.load();
    notifyListeners();
  }

  Future<void> _update(StickerBookData next) async {
    _data = next;
    notifyListeners();
    await _repository.save(next);
  }

  List<StickerPlacement> placementsFor(String sceneId) =>
      _data.forScene(sceneId);

  /// Places a sticker at scene-relative coordinates (0..1).
  Future<void> placeSticker(String stickerId, String sceneId, double x,
      double y) async {
    await _update(
      StickerBookData(
        placements: [
          ..._data.placements,
          StickerPlacement(
            stickerId: stickerId,
            sceneId: sceneId,
            x: x.clamp(0.0, 1.0),
            y: y.clamp(0.0, 1.0),
          ),
        ],
      ),
    );
  }

  Future<void> movePlacement(int index, double x, double y) async {
    if (index < 0 || index >= _data.placements.length) return;
    final placements = [..._data.placements];
    placements[index] =
        placements[index].moved(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
    await _update(StickerBookData(placements: placements));
  }

  Future<void> removePlacement(int index) async {
    if (index < 0 || index >= _data.placements.length) return;
    final placements = [..._data.placements]..removeAt(index);
    await _update(StickerBookData(placements: placements));
  }

  Future<void> reset() => _update(StickerBookData());

  Future<void> reloadFromStore() async {
    _data = await _repository.load();
    notifyListeners();
  }
}
