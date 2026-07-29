import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../game/toddler_game.dart';
import 'draggable_item.dart';
import 'gentle_effects.dart';

/// A destination for [DraggableItem]s with a generous snap radius.
///
/// Zones register themselves with the owning [ToddlerGame] on mount; the
/// game resolves drops to the nearest willing zone.
class DropZone extends PositionComponent with HasGameReference<ToddlerGame> {
  DropZone({
    required this.zoneId,
    super.position,
    required Vector2 super.size,
    double? snapRadius,
    this.acceptTest,
    this.onAccepted,
    this.paintZone,
    this.enabled = true,
    super.priority = 1,
  })  : snapRadius = snapRadius ?? size.length / 2 + 60,
        super(anchor: Anchor.center);

  final String zoneId;

  /// Distance from the zone centre within which a drop may snap. Defaults
  /// to well beyond the visual bounds — toddlers never need precision.
  final double snapRadius;

  /// Which items belong here. Defaults to matching [DraggableItem.itemId]
  /// with [zoneId]. Mutable so subclasses can bind a test to `this`.
  bool Function(DraggableItem item)? acceptTest;

  /// Called after an accepted item finished snapping into place.
  void Function(DraggableItem item)? onAccepted;

  /// Draws the zone (e.g. a silhouette); receives the local size.
  final void Function(Canvas canvas, Vector2 size)? paintZone;

  bool enabled;

  GlowHighlight? _glow;

  bool accepts(DraggableItem item) =>
      acceptTest?.call(item) ?? item.itemId == zoneId;

  @override
  void onMount() {
    super.onMount();
    game.dropZones.add(this);
  }

  @override
  void onRemove() {
    game.dropZones.remove(this);
    super.onRemove();
  }

  /// Soft pulsing glow used by hints and the escalation ladder.
  void showHighlight() {
    if (_glow != null && _glow!.isMounted) return;
    _glow = GlowHighlight(radius: snapRadius * 0.72);
    add(_glow!..position = Vector2(size.x / 2, size.y / 2));
  }

  void hideHighlight() {
    _glow?.dismiss();
    _glow = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    paintZone?.call(canvas, size);
  }
}
