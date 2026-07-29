import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../game/toddler_game.dart';
import 'gentle_effects.dart';

/// A very large tap target. Reacts on touch-down (no release precision or
/// double taps needed) and pads its hit area generously.
class TapTarget extends PositionComponent
    with TapCallbacks, HasGameReference<ToddlerGame> {
  TapTarget({
    required this.targetId,
    super.position,
    required Vector2 super.size,
    this.paintItem,
    this.onPressed,
    this.hitPadding = 24,
    this.enabled = true,
    super.priority = 10,
  }) : super(anchor: Anchor.center);

  final String targetId;

  final void Function(Canvas canvas, Vector2 size)? paintItem;

  void Function(TapTarget target)? onPressed;

  final double hitPadding;

  bool enabled;

  GlowHighlight? _glow;

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= -hitPadding &&
        point.y >= -hitPadding &&
        point.x <= size.x + hitPadding &&
        point.y <= size.y + hitPadding;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!enabled) return;
    game.resetHintCountdown();
    game.gameContext.haptics.tap();
    onPressed?.call(this);
  }

  /// Gentle attention pulse for hints.
  void pulse() {
    if (game.reducedMotion) {
      showHighlight();
      return;
    }
    add(GentleEffects.attentionPulse());
  }

  void showHighlight() {
    if (_glow != null && _glow!.isMounted) return;
    _glow = GlowHighlight(radius: size.length / 2 + 18);
    add(_glow!..position = Vector2(size.x / 2, size.y / 2));
  }

  void hideHighlight() {
    _glow?.dismiss();
    _glow = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    paintItem?.call(canvas, size);
  }
}
