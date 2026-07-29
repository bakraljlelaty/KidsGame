import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../core/audio/sound_effects.dart';
import '../game/toddler_game.dart';

/// A layer of soft "dirt" blobs the child wipes away by swiping.
///
/// Used by the Muddy Pig Bath; generic enough for any clean-the-surface
/// activity. Erosion is very forgiving: any drag near a blob removes it.
class SwipeCleanLayer extends PositionComponent
    with DragCallbacks, HasGameReference<ToddlerGame> {
  SwipeCleanLayer({
    super.position,
    required Vector2 super.size,
    this.blobCount = 14,
    this.blobColor = const Color(0xFFB08A62),
    this.eraseRadius = 58,
    this.onProgress,
    this.onCleaned,
    this.onScrubStart,
    this.onScrubMove,
    this.onScrubEnd,
    super.priority = 20,
  }) : super(anchor: Anchor.topLeft);

  final int blobCount;
  final Color blobColor;

  /// How close the finger must pass to wipe a blob (very generous).
  final double eraseRadius;

  final void Function(double progress)? onProgress;
  final VoidCallback? onCleaned;

  /// Hooks so the host game can show a sponge following the finger.
  final void Function(Vector2 localPos)? onScrubStart;
  final void Function(Vector2 localPos)? onScrubMove;
  final VoidCallback? onScrubEnd;

  final List<_MudBlob> _blobs = [];
  Vector2 _cursor = Vector2.zero();
  bool _scrubbing = false;
  double _soundCooldown = 0;
  bool _finished = false;

  static final math.Random _random = math.Random();

  bool get isClean => _blobs.every((b) => !b.alive);

  double get progress {
    if (_blobs.isEmpty) return 1;
    final removed = _blobs.where((b) => !b.alive).length;
    return removed / _blobs.length;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Scatter blobs inside an ellipse covering the layer.
    for (var i = 0; i < blobCount; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final rx = (size.x / 2 - 24) * math.sqrt(_random.nextDouble());
      final ry = (size.y / 2 - 20) * math.sqrt(_random.nextDouble());
      _blobs.add(
        _MudBlob(
          center: Vector2(
            size.x / 2 + math.cos(angle) * rx,
            size.y / 2 + math.sin(angle) * ry,
          ),
          radius: 22 + _random.nextDouble() * 20,
          wobble: _random.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _scrubbing = true;
    _cursor = event.localPosition.clone();
    game.resetHintCountdown();
    onScrubStart?.call(_cursor.clone());
    _erodeAt(_cursor);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_scrubbing) return;
    _cursor += event.localDelta;
    onScrubMove?.call(_cursor.clone());
    _erodeAt(_cursor);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _scrubbing = false;
    onScrubEnd?.call();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _scrubbing = false;
    onScrubEnd?.call();
  }

  void _erodeAt(Vector2 point) {
    if (_finished) return;
    var changed = false;
    for (final blob in _blobs) {
      if (blob.alive && blob.center.distanceTo(point) <= eraseRadius) {
        blob.alive = false;
        blob.fade = 1.0;
        changed = true;
      }
    }
    if (!changed) return;

    if (_soundCooldown <= 0) {
      game.playEffect(SoundEffect.waterSplash);
      _soundCooldown = 0.5;
    }
    game.gameContext.haptics.tap();
    onProgress?.call(progress);
    if (isClean) {
      _finished = true;
      onCleaned?.call();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_soundCooldown > 0) _soundCooldown -= dt;
    for (final blob in _blobs) {
      if (!blob.alive && blob.fade > 0) {
        blob.fade = math.max(0, blob.fade - dt * 2.4);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final blob in _blobs) {
      final alpha = blob.alive ? 0.85 : 0.85 * blob.fade;
      if (alpha <= 0.01) continue;
      final paint = Paint()
        ..color = blobColor.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(blob.center.x, blob.center.y),
          width: blob.radius * 2.2,
          height: blob.radius * 1.7,
        ),
        paint,
      );
    }
  }
}

class _MudBlob {
  _MudBlob({required this.center, required this.radius, required this.wobble});

  final Vector2 center;
  final double radius;
  final double wobble;
  bool alive = true;
  double fade = 1.0;
}
