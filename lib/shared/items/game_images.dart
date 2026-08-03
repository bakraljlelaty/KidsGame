import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Cache of the illustrated art set (assets/images/**), decoded once at
/// startup. Every consumer falls back to procedural drawing when an image
/// is absent, so the art set can grow (or be removed) freely — including in
/// tests, which skip loading entirely.
class GameImages {
  GameImages._();

  static final Map<String, ui.Image> _items = {};
  static final Map<String, ui.Image> _milo = {};
  static final Map<String, ui.Image> _scenes = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final asset in manifest.listAssets()) {
        if (!asset.startsWith('assets/images/')) continue;
        final stem = asset.split('/').last.split('.').first;
        try {
          if (asset.contains('/items/')) {
            _items[stem] = await _decode(asset, targetWidth: 320);
          } else if (asset.contains('/milo/')) {
            _milo[stem] = await _decode(asset, targetWidth: 512);
          } else if (asset.contains('/scenes/')) {
            _scenes[stem] = await _decode(asset);
          }
        } catch (e) {
          debugPrint('GameImages: failed to load $asset: $e');
        }
      }
      debugPrint('GameImages: ${_items.length} items, ${_milo.length} milo, '
          '${_scenes.length} scenes');
    } catch (e) {
      // No manifest / no images — procedural art carries the whole app.
      debugPrint('GameImages: $e');
    }
  }

  static Future<ui.Image> _decode(String asset, {int? targetWidth}) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    return (await codec.getNextFrame()).image;
  }

  static ui.Image? item(String artId) => _items[artId];
  static ui.Image? milo(String stateName) => _milo[stateName];
  static ui.Image? scene(String sceneId) => _scenes[sceneId];

  static final Paint _paint = Paint()
    ..filterQuality = FilterQuality.medium;

  /// Draws [image] scaled to fit inside [size], centered.
  static void drawContain(ui.Image image, Canvas canvas, Size size) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale =
        (size.width / iw) < (size.height / ih) ? size.width / iw : size.height / ih;
    final w = iw * scale;
    final h = ih * scale;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, iw, ih),
      Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h),
      _paint,
    );
  }

  /// Draws [image] scaled to cover [size], centered (crops overflow).
  static void drawCover(ui.Image image, Canvas canvas, Size size) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale =
        (size.width / iw) > (size.height / ih) ? size.width / iw : size.height / ih;
    final w = size.width / scale;
    final h = size.height / scale;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH((iw - w) / 2, (ih - h) / 2, w, h),
      Rect.fromLTWH(0, 0, size.width, size.height),
      _paint,
    );
  }
}
