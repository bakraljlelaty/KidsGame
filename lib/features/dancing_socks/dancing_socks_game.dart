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
import 'sock_art.dart';
import '../../shared/items/game_images.dart';

/// Mini-game: Dancing Socks.
///
/// A cosy bedroom; one sock of each pair waits by the dresser on the left,
/// its partner lies scattered on the rug to the right. The child drags each
/// loose sock onto its matching partner. A reunited pair "comes alive" —
/// both socks get little faces and do a happy dance. Matching every pair
/// completes the activity.
///
/// Stage decides how many pairs appear and how they are told apart:
/// explorer 1 obvious pair, helper 2 pairs by colour, littleThinker 3 pairs
/// by pattern + colour.
class DancingSocksGame extends ToddlerGame {
  DancingSocksGame(super.gameContext);

  final List<_SockZone> _zones = [];
  final List<_SockItem> _items = [];

  @override
  Color backgroundColor() => Palette.peach;

  int get _pairCount => stage.maxActiveTargets.clamp(1, 3);

  List<SockStyle> get _stylesForStage => switch (_pairCount) {
        1 => const [SockStyles.plainBlue],
        2 => const [SockStyles.plainBlue, SockStyles.dottyPink],
        _ => const [
            SockStyles.stripyBlue,
            SockStyles.dottyBlue,
            SockStyles.dottyPink,
          ],
      };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(_BedroomBackground(size: size.clone()));
    await addMilo();

    final styles = _stylesForStage;
    final sockSize = Vector2(120, 126) * stage.itemScale;

    // One sock of each pair waits on the left, by the dresser (drop zones).
    final zoneYs = switch (styles.length) {
      1 => const [0.45],
      2 => const [0.32, 0.62],
      _ => const [0.26, 0.50, 0.74],
    };
    for (var i = 0; i < styles.length; i++) {
      final zone = _SockZone(
        style: styles[i],
        position: Vector2(size.x * 0.29, size.y * zoneYs[i]),
        size: sockSize.clone(),
        onMatched: _onPairMatched,
      );
      _zones.add(zone);
      await add(zone);
    }

    // Partners scattered on the right, shuffled so position never encodes
    // the answer.
    final slots = switch (styles.length) {
      1 => const [Offset(0.70, 0.52)],
      2 => const [Offset(0.63, 0.38), Offset(0.80, 0.64)],
      _ => const [Offset(0.60, 0.33), Offset(0.83, 0.48), Offset(0.66, 0.70)],
    };
    final shuffled = [...styles]..shuffle(math.Random());
    for (var i = 0; i < shuffled.length; i++) {
      final item = _SockItem(
        style: shuffled[i],
        position: Vector2(size.x * slots[i].dx, size.y * slots[i].dy),
        size: sockSize.clone(),
      );
      _items.add(item);
      await add(item);
    }

    say(VoiceInstruction.socksIntro);
    add(
      TimerComponent(
        period: 2.4,
        removeOnFinish: true,
        onTick: () => say(VoiceInstruction.socksFind),
      ),
    );
    startHintCountdown();
  }

  _SockZone? get _currentZone {
    for (final zone in _zones) {
      if (!zone.matched) return zone;
    }
    return null;
  }

  _SockItem? get _currentItem {
    final zone = _currentZone;
    if (zone == null) return null;
    for (final item in _items) {
      if (item.itemId == zone.style.id && !item.alive) return item;
    }
    return null;
  }

  void _onPairMatched(_SockZone zone, DraggableItem item) {
    registerCorrectAction();
    zone.hideHighlight();
    playEffect(SoundEffect.sparkle);

    final sock = item as _SockItem;
    zone.alive = true;
    sock.alive = true;
    sock.draggable = false;
    milo?.laugh();
    add(SparkleBurst(at: zone.position.clone(), reducedMotion: reducedMotion));

    // The pair stands side by side, toes towards each other, and dances.
    final sideStep = Vector2(zone.size.x * 0.72, 0);
    if (reducedMotion) {
      sock.position = zone.position + sideStep;
    } else {
      sock.add(
        MoveByEffect(
          sideStep,
          EffectController(duration: 0.22, curve: Curves.easeOut),
          onComplete: () {
            sock.add(GentleEffects.happyHop(height: 16));
            sock.add(GentleEffects.wobble(angle: 0.06, repeats: 2));
          },
        ),
      );
      zone.add(GentleEffects.happyHop(height: 16));
      zone.add(GentleEffects.wobble(angle: 0.06, repeats: 2));
    }

    add(TimerComponent(period: 1.6, removeOnFinish: true, onTick: _afterDance));
  }

  void _afterDance() {
    if (_zones.every((zone) => zone.matched)) {
      completeGame(voice: VoiceInstruction.wellDone);
    } else {
      say(VoiceInstruction.socksFind);
    }
  }

  @override
  void showHint() {
    final zone = _currentZone;
    final item = _currentItem;
    if (zone == null || item == null) return;
    if (!reducedMotion) item.add(GentleEffects.attentionPulse());
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
  void repeatInstruction() => say(VoiceInstruction.socksFind);

  @override
  void highlightTarget() {
    _currentZone?.showHighlight();
    say(VoiceInstruction.socksFind);
  }

  @override
  void autoAssist() {
    // Gently carry the loose sock to its waiting partner for the child.
    final zone = _currentZone;
    final item = _currentItem;
    if (zone == null || item == null) return;
    zone.hideHighlight();
    item.draggable = false;
    item.snapToZone(zone, onArrived: () => zone.onAccepted?.call(item));
  }
}

/// The waiting sock of a pair: a drop zone that only accepts its partner.
class _SockZone extends DropZone {
  _SockZone({
    required this.style,
    required super.position,
    required super.size,
    required void Function(_SockZone zone, DraggableItem item) onMatched,
  }) : super(zoneId: style.id) {
    acceptTest = (item) => !matched && item.itemId == style.id;
    onAccepted = (item) {
      if (matched) return;
      matched = true;
      enabled = false;
      onMatched(this, item);
    };
  }

  final SockStyle style;
  bool matched = false;

  /// Once the pair is together the sock gets a face.
  bool alive = false;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    SockArt.paintSock(
      canvas,
      size,
      style,
      alive: alive,
      flip: true,
      highContrast: game.highContrast,
    );
  }
}

/// The loose sock the child drags to its partner.
class _SockItem extends DraggableItem {
  _SockItem({
    required this.style,
    required super.position,
    required super.size,
  }) : super(itemId: style.id);

  final SockStyle style;

  /// Once the pair is together the sock gets a face.
  bool alive = false;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    SockArt.paintSock(
      canvas,
      size,
      style,
      alive: alive,
      highContrast: game.highContrast,
    );
  }
}

/// Soft bedroom backdrop. Pure decoration, zero interaction.
class _BedroomBackground extends PositionComponent {
  _BedroomBackground({required Vector2 size}) : super(size: size, priority: -10);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sceneImage = GameImages.scene('scene_bedroom');
    if (sceneImage != null) {
      GameImages.drawCover(sceneImage, canvas, Size(size.x, size.y));
      return;
    }
    SockArt.paintBedroom(canvas, size);
  }
}
