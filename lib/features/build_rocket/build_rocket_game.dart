import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../core/audio/sound_effects.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/theme/palette.dart';
import '../../shared/components/draggable_item.dart';
import '../../shared/components/drop_zone.dart';
import '../../shared/components/gentle_effects.dart';
import '../../shared/game/toddler_game.dart';
import 'rocket_art.dart';

/// Mini-game: Build the Rocket.
///
/// A cosy space workshop. Dark silhouettes on the workbench show where each
/// rocket part belongs; the child drags parts from the tray into place, in
/// any order. Stage decides the part count (2..4). When the rocket is whole
/// its little lights glow softly, Milo puts his helmet on and the rocket
/// drifts gently off the top of the screen with a sparkle trail.
class BuildRocketGame extends ToddlerGame {
  BuildRocketGame(super.gameContext);

  /// Horizontal centre of the assembly area (centre-left of the scene).
  static const double _assemblyXFactor = 0.36;

  /// The rocket stands on the workbench at this fraction of the height.
  static const double _assemblyBottomFactor = 0.70;

  final List<_PartZone> _zones = [];
  final List<DraggableItem> _trayParts = [];

  /// Placed parts and the lights live under this one parent so the launch
  /// simply moves a single component upward.
  late final PositionComponent _rocketGroup;
  late final Rect _bodyRectLocal;

  bool _launching = false;
  TimerComponent? _trailTimer;

  @override
  Color backgroundColor() => Palette.lavender;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final parts = RocketPart.forCount(stage.puzzlePieceCount);
    final hasBase = parts.contains(RocketPart.base);

    // Every part size derives from the body width, chosen so the whole
    // stack fits above the workbench on any screen; stage.itemScale nudges
    // parts larger for younger builders.
    final stackUnits = 0.72 + 1.22 + (hasBase ? 0.55 : 0.0);
    final bodyW = math
        .min(size.x * 0.14 * stage.itemScale, size.y * 0.52 / stackUnits)
        .clamp(96.0, 190.0)
        .toDouble();
    final noseH = bodyW * 0.72;
    final bodyH = bodyW * 1.22;
    final baseH = hasBase ? bodyW * 0.55 : 0.0;

    final groupW = hasBase ? bodyW * 1.45 : bodyW;
    final groupH = noseH + bodyH + baseH;
    final groupCx = groupW / 2;
    final assemblyCx = size.x * _assemblyXFactor;
    final groupTopLeft = Vector2(
      assemblyCx - groupW / 2,
      size.y * _assemblyBottomFactor - groupH,
    );

    _bodyRectLocal = Rect.fromCenter(
      center: Offset(groupCx, noseH + bodyH / 2),
      width: bodyW,
      height: bodyH,
    );

    Vector2 partSize(RocketPart part) => switch (part) {
          RocketPart.nose => Vector2(bodyW, noseH),
          RocketPart.body => Vector2(bodyW, bodyH),
          RocketPart.window => Vector2.all(bodyW * 0.88),
          RocketPart.base => Vector2(bodyW * 1.45, baseH),
        };

    Vector2 localCenter(RocketPart part) => switch (part) {
          RocketPart.nose => Vector2(groupCx, noseH / 2),
          RocketPart.body => Vector2(groupCx, noseH + bodyH / 2),
          RocketPart.window => Vector2(groupCx, noseH + bodyH * 0.38),
          RocketPart.base => Vector2(groupCx, noseH + bodyH + baseH / 2),
        };

    // Tray band along the bottom, kept clear of Milo's corner.
    final trayY = math.min(size.y * 0.88, size.y - bodyH / 2 - 12);
    final trayStart = gameContext.leftHanded ? size.x * 0.05 : size.x * 0.24;
    final trayEnd = gameContext.leftHanded ? size.x * 0.76 : size.x * 0.97;
    final trayRect = Rect.fromLTRB(
      math.max(8.0, trayStart - 24),
      trayY - bodyH * 0.34,
      math.min(size.x - 8.0, trayEnd + 24),
      size.y * 0.975,
    );

    await add(_WorkshopBackground(
      size: size.clone(),
      trayRect: trayRect,
      assemblyCx: assemblyCx,
    ));

    _rocketGroup = PositionComponent(
      position: groupTopLeft,
      size: Vector2(groupW, groupH),
      priority: 2,
    );
    await add(_rocketGroup);

    // One silhouette drop zone per part, at its spot on the rocket.
    for (final part in parts) {
      final zoneSize = partSize(part);
      final zone = _PartZone(
        part: part,
        localCenter: localCenter(part),
        position: groupTopLeft + localCenter(part),
        size: zoneSize,
        // Extra generous: toddlers never need precision.
        snapRadius: zoneSize.length / 2 + 80,
        onPlaced: _onPartPlaced,
      );
      _zones.add(zone);
      await add(zone);
    }

    // Draggable parts in the tray, shuffled so position never encodes the
    // answer.
    final shuffled = [...parts]..shuffle(math.Random());
    for (var i = 0; i < shuffled.length; i++) {
      final part = shuffled[i];
      final x = trayStart + (trayEnd - trayStart) * (i + 0.5) / shuffled.length;
      final item = DraggableItem(
        itemId: part.id,
        position: Vector2(x, trayY),
        size: partSize(part),
        hitPadding: 28,
        paintItem: (canvas, itemSize) =>
            RocketArt.paintPart(canvas, itemSize, part),
      );
      _trayParts.add(item);
      await add(item);
    }

    await addMilo();

    say(VoiceInstruction.rocketIntro);
    add(
      TimerComponent(
        period: 2.4,
        removeOnFinish: true,
        onTick: _announceNextPart,
      ),
    );
    startHintCountdown();
  }

  // ------------------------------------------------------------ helpers

  /// The lowest silhouette still waiting for its part (hints suggest
  /// building bottom-to-top, though any order is accepted).
  _PartZone? get _nextZone {
    for (final zone in _zones) {
      if (!zone.filled) return zone;
    }
    return null;
  }

  DraggableItem? _trayItemFor(_PartZone zone) {
    for (final item in _trayParts) {
      if (item.itemId == zone.part.id) return item;
    }
    return null;
  }

  void _announceNextPart() {
    if (_launching || isCompleted || _nextZone == null) return;
    say(VoiceInstruction.rocketPiece);
  }

  /// The porthole silhouette overlaps the body silhouette, so instead of
  /// only checking the single nearest zone we prefer the nearest zone that
  /// actually wants this part — a correct drop near two zones never counts
  /// as a mistake.
  @override
  bool resolveDrop(DraggableItem item) {
    DropZone? nearestAccepting;
    DropZone? nearestAny;
    var bestAccepting = double.infinity;
    var bestAny = double.infinity;
    for (final zone in dropZones) {
      if (!zone.enabled) continue;
      final distance = zone.absoluteCenter.distanceTo(item.absoluteCenter);
      if (distance > zone.snapRadius) continue;
      if (distance < bestAny) {
        bestAny = distance;
        nearestAny = zone;
      }
      if (zone.accepts(item) && distance < bestAccepting) {
        bestAccepting = distance;
        nearestAccepting = zone;
      }
    }

    final target = nearestAccepting;
    if (target != null) {
      item.snapToZone(target, onArrived: () => target.onAccepted?.call(item));
      gameContext.haptics.success();
      return true;
    }
    if (nearestAny != null) {
      // Dropped onto a silhouette that belongs to a different part.
      handleWrongAttempt(item: item);
      return false;
    }
    // Dropped in empty space: not a mistake, just drift gently home.
    item.returnHome(playSound: false);
    return false;
  }

  // ------------------------------------------------------ part placement

  void _onPartPlaced(_PartZone zone, DraggableItem item) {
    registerCorrectAction();
    _trayParts.remove(item);

    // Add the placed art before removing the dragged copy — no flicker.
    _rocketGroup.add(_PlacedPart(
      part: zone.part,
      position: zone.localCenter,
      size: zone.size.clone(),
      reducedMotion: reducedMotion,
    ));
    item.removeFromParent();

    add(SparkleBurst(at: zone.position.clone(), reducedMotion: reducedMotion));
    milo?.laugh(duration: const Duration(milliseconds: 1200));

    if (_zones.every((z) => z.filled)) {
      _beginLaunch();
    } else {
      add(
        TimerComponent(
          period: 1.3,
          removeOnFinish: true,
          onTick: _announceNextPart,
        ),
      );
    }
  }

  // -------------------------------------------------------------- launch

  void _beginLaunch() {
    if (_launching) return;
    _launching = true;
    stopHintCountdown();

    // The little lights wake up: slow, soft alternating glow — no strobing.
    _rocketGroup.add(_RocketLights(
      bodyRect: _bodyRectLocal,
      reducedMotion: reducedMotion,
    ));
    milo?.wearsHelmet = true;
    milo?.celebrate(duration: const Duration(seconds: 3));
    say(VoiceInstruction.rocketLaunch);

    add(TimerComponent(period: 1.5, removeOnFinish: true, onTick: _liftOff));
  }

  void _liftOff() {
    playEffect(SoundEffect.slide);
    if (!reducedMotion) {
      _trailTimer = TimerComponent(
        period: 0.3,
        repeat: true,
        onTick: _emitTrailSparkle,
      );
      add(_trailTimer!);
    }
    final rise = _rocketGroup.position.y + _rocketGroup.size.y + 80;
    _rocketGroup.add(
      MoveByEffect(
        Vector2(0, -rise),
        EffectController(
          duration: reducedMotion ? 1.6 : 3.0,
          curve: Curves.easeInQuad,
        ),
        onComplete: _onRocketAway,
      ),
    );
  }

  void _emitTrailSparkle() {
    final at = Vector2(
      _rocketGroup.position.x + _rocketGroup.size.x / 2,
      _rocketGroup.position.y + _rocketGroup.size.y + 6,
    );
    if (at.y < -40) return;
    add(SparkleBurst(
      at: at,
      reducedMotion: reducedMotion,
      count: 7,
      color: Palette.butter,
    ));
  }

  void _onRocketAway() {
    _trailTimer?.removeFromParent();
    _trailTimer = null;
    completeGame(voice: VoiceInstruction.greatJob);
  }

  // --------------------------------------------------------------- hints

  @override
  void showHint() {
    if (_launching || isCompleted) return;
    final zone = _nextZone;
    if (zone == null) return;
    final item = _trayItemFor(zone);
    if (item == null || !item.draggable || item.isDragging) return;
    item.add(GentleEffects.attentionPulse());
    zone.showHighlight();
    milo?.pointTowards(item.position.x >= size.x / 2 ? 1 : -1);
    add(
      TimerComponent(
        period: 2.5,
        removeOnFinish: true,
        onTick: zone.hideHighlight,
      ),
    );
  }

  @override
  void repeatInstruction() => _announceNextPart();

  @override
  void highlightTarget() {
    if (_launching || isCompleted) return;
    final zone = _nextZone;
    if (zone == null) return;
    zone.showHighlight();
    add(
      TimerComponent(
        period: 2.5,
        removeOnFinish: true,
        onTick: zone.hideHighlight,
      ),
    );
    _announceNextPart();
  }

  @override
  void autoAssist() {
    // Gently float the next part into its spot so nobody gets stuck.
    if (_launching || isCompleted) return;
    final zone = _nextZone;
    if (zone == null) return;
    final item = _trayItemFor(zone);
    if (item == null || !item.draggable || item.isDragging) return;
    zone.hideHighlight();
    item.draggable = false;
    item.snapToZone(zone, onArrived: () => zone.onAccepted?.call(item));
  }
}

/// A silhouette drop zone for exactly one rocket part. Draws the dark
/// translucent outline until its part arrives, then disappears.
class _PartZone extends DropZone {
  _PartZone({
    required this.part,
    required this.localCenter,
    required super.position,
    required super.size,
    required super.snapRadius,
    required void Function(_PartZone zone, DraggableItem item) onPlaced,
  }) : super(
          zoneId: part.id,
          priority: 6,
        ) {
    acceptTest = (item) => !filled && item.itemId == part.id;
    onAccepted = (item) {
      if (filled) return;
      filled = true;
      enabled = false;
      hideHighlight();
      onPlaced(this, item);
    };
  }

  final RocketPart part;

  /// Where the part sits inside the rocket group (its local centre).
  final Vector2 localCenter;

  bool filled = false;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!filled) RocketArt.paintSilhouette(canvas, size, part);
  }
}

/// A part that has been placed on the rocket; lives inside the rocket group
/// so lift-off moves everything together.
class _PlacedPart extends PositionComponent {
  _PlacedPart({
    required this.part,
    required Vector2 position,
    required Vector2 size,
    required bool reducedMotion,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
          priority: part.layer,
        ) {
    if (!reducedMotion) {
      scale = Vector2.all(0.92);
      add(GentleEffects.popIn());
    }
  }

  final RocketPart part;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    RocketArt.paintPart(canvas, size, part);
  }
}

/// Three little pastel lights on the body panel that glow with a very slow
/// alternating pulse (static soft glow when reduced motion is on).
class _RocketLights extends PositionComponent {
  _RocketLights({required this.bodyRect, required this.reducedMotion})
      : super(priority: 10);

  final Rect bodyRect;
  final bool reducedMotion;

  static const _colors = [Palette.butter, Palette.mint, Palette.blush];

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cy = bodyRect.top + bodyRect.height * 0.76;
    final r = bodyRect.width * 0.065;
    for (var i = 0; i < _colors.length; i++) {
      final cx = bodyRect.left + bodyRect.width * (0.28 + 0.22 * i);
      final phase = _time * 2 * math.pi / 2.2 + i * 2 * math.pi / 3;
      final glow =
          reducedMotion ? 0.8 : 0.5 + 0.35 * math.sin(phase); // 0.15..0.85
      canvas.drawCircle(
        Offset(cx, cy),
        r * 1.9,
        Paint()
          ..color = _colors[i].withValues(alpha: glow * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = _colors[i].withValues(alpha: 0.35 + glow * 0.6),
      );
    }
  }
}

/// Thin component shell over [WorkshopArt]; pure decoration.
class _WorkshopBackground extends PositionComponent {
  _WorkshopBackground({
    required Vector2 size,
    required this.trayRect,
    required this.assemblyCx,
  }) : super(size: size, priority: -10);

  final Rect trayRect;
  final double assemblyCx;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    WorkshopArt.paintWorkshop(
      canvas,
      size,
      trayRect: trayRect,
      assemblyCx: assemblyCx,
    );
  }
}
