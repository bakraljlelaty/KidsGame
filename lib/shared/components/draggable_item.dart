import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../core/audio/sound_effects.dart';
import '../game/toddler_game.dart';
import 'drop_zone.dart';

/// A large, forgiving draggable object.
///
/// Rendering is delegated to [paintItem] (or a subclass override) so the
/// same interaction works for any placeholder or future sprite art. The hit
/// area is padded well beyond the visual bounds because toddler fingers are
/// imprecise.
class DraggableItem extends PositionComponent
    with DragCallbacks, HasGameReference<ToddlerGame> {
  DraggableItem({
    required this.itemId,
    super.position,
    required Vector2 super.size,
    this.paintItem,
    this.hitPadding = 24,
    this.draggable = true,
    super.priority = 10,
  }) : super(anchor: Anchor.center);

  final String itemId;

  /// Draws the item; receives the component-local size.
  final void Function(Canvas canvas, Vector2 size)? paintItem;

  final double hitPadding;

  bool draggable;

  /// Where the item returns when a drop is not accepted.
  late Vector2 homePosition;

  bool _homeSet = false;
  bool _dragging = false;
  bool get isDragging => _dragging;

  /// Set false while snap/return effects run so the child can't grab a
  /// moving object into a broken state.
  bool _settling = false;

  int _basePriority = 10;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!_homeSet) setHome(position.clone());
    _basePriority = priority;
  }

  void setHome(Vector2 home) {
    homePosition = home.clone();
    _homeSet = true;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= -hitPadding &&
        point.y >= -hitPadding &&
        point.x <= size.x + hitPadding &&
        point.y <= size.y + hitPadding;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!draggable || _settling) return;
    _dragging = true;
    priority = 100;
    game.resetHintCountdown();
    game.gameContext.haptics.tap();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_dragging) return;
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_dragging) return;
    _dragging = false;
    priority = _basePriority;
    game.resolveDrop(this);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (!_dragging) return;
    _dragging = false;
    priority = _basePriority;
    returnHome(playSound: false);
  }

  /// Drifts gently back to [homePosition] — the "no, but no drama" motion.
  void returnHome({bool playSound = true, VoidCallback? onArrived}) {
    if (playSound) game.playEffect(SoundEffect.slide);
    _settling = true;
    add(
      MoveToEffect(
        homePosition,
        EffectController(
          duration: game.reducedMotion ? 0.15 : 0.45,
          curve: Curves.easeOutBack,
        ),
        onComplete: () {
          _settling = false;
          onArrived?.call();
        },
      ),
    );
  }

  /// Snaps into [zone] (generous distance), disabling further dragging.
  void snapToZone(DropZone zone, {VoidCallback? onArrived}) {
    draggable = false;
    _settling = true;
    final delta = zone.absoluteCenter - absoluteCenter;
    game.playEffect(SoundEffect.ding);
    add(
      MoveByEffect(
        delta,
        EffectController(
          duration: game.reducedMotion ? 0.1 : 0.22,
          curve: Curves.easeOut,
        ),
        onComplete: () {
          _settling = false;
          onArrived?.call();
        },
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    paintItem?.call(canvas, size);
  }
}
