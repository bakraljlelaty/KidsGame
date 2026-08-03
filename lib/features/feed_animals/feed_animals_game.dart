import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/audio/sound_effects.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/theme/palette.dart';
import '../../shared/components/draggable_item.dart';
import '../../shared/components/drop_zone.dart';
import '../../shared/components/gentle_effects.dart';
import '../../shared/game/toddler_game.dart';
import 'animal_art.dart';
import '../../shared/items/game_images.dart';

/// Mini-game 1: Feed the Animals.
///
/// A friendly farm; the child drags each food to the animal that eats it.
/// Stage decides how many animal/food pairs appear (1..3). Feeding every
/// animal completes the activity.
class FeedAnimalsGame extends ToddlerGame {
  FeedAnimalsGame(super.gameContext);

  static const _order = [AnimalKind.rabbit, AnimalKind.cow, AnimalKind.monkey];

  final List<_AnimalZone> _animals = [];
  final List<DraggableItem> _foods = [];

  @override
  Color backgroundColor() => Palette.skyDay;

  int get _pairCount => stage.maxActiveTargets.clamp(1, _order.length);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(_FarmBackground(size: size.clone()));
    await addMilo();

    final kinds = _order.take(_pairCount).toList();
    final scale = stage.itemScale;

    // Animals across the upper area.
    final animalSize = Vector2(170, 170) * scale;
    for (var i = 0; i < kinds.length; i++) {
      final x = size.x * (i + 1) / (kinds.length + 1);
      final zone = _AnimalZone(
        kind: kinds[i],
        position: Vector2(x, size.y * 0.36),
        size: animalSize,
        onFed: _onAnimalFed,
      );
      _animals.add(zone);
      await add(zone);
    }

    // Foods along the bottom, shuffled so position never encodes the answer.
    final foodSize = Vector2(110, 110) * scale;
    final shuffled = [...kinds]..shuffle(math.Random());
    for (var i = 0; i < shuffled.length; i++) {
      final x = size.x * (i + 1) / (shuffled.length + 1);
      final food = DraggableItem(
        itemId: shuffled[i].foodId,
        position: Vector2(x, size.y * 0.82),
        size: foodSize,
        paintItem: (canvas, itemSize) =>
            AnimalArt.paintFood(canvas, itemSize, shuffled[i].foodId),
      );
      _foods.add(food);
      await add(food);
    }

    say(VoiceInstruction.feedIntro);
    add(
      TimerComponent(
        period: 2.2,
        removeOnFinish: true,
        onTick: _announceCurrent,
      ),
    );
    startHintCountdown();
  }

  _AnimalZone? get _currentZone {
    for (final animal in _animals) {
      if (!animal.fed) return animal;
    }
    return null;
  }

  DraggableItem? get _currentFood {
    final zone = _currentZone;
    if (zone == null) return null;
    for (final food in _foods) {
      if (food.itemId == zone.kind.foodId) return food;
    }
    return null;
  }

  void _announceCurrent() {
    final zone = _currentZone;
    if (zone == null) return;
    say(switch (zone.kind) {
      AnimalKind.rabbit => VoiceInstruction.feedRabbit,
      AnimalKind.cow => VoiceInstruction.feedCow,
      AnimalKind.monkey => VoiceInstruction.feedMonkey,
    });
  }

  void _onAnimalFed(_AnimalZone zone, DraggableItem food) {
    registerCorrectAction();
    playEffect(SoundEffect.chew);
    _foods.remove(food);
    food.removeFromParent();
    add(SparkleBurst(
      at: zone.position.clone(),
      reducedMotion: reducedMotion,
    ));
    milo?.laugh();

    if (_animals.every((a) => a.fed)) {
      completeGame(voice: VoiceInstruction.wellDone);
    } else {
      add(
        TimerComponent(
          period: 1.6,
          removeOnFinish: true,
          onTick: _announceCurrent,
        ),
      );
    }
  }

  @override
  void showHint() {
    final zone = _currentZone;
    final food = _currentFood;
    if (zone == null || food == null) return;
    food.add(GentleEffects.attentionPulse());
    zone.showHighlight();
    milo?.pointTowards(food.position.x >= size.x / 2 ? 1 : -1);
    add(
      TimerComponent(
        period: 2.5,
        removeOnFinish: true,
        onTick: zone.hideHighlight,
      ),
    );
  }

  @override
  void repeatInstruction() => _announceCurrent();

  @override
  void highlightTarget() {
    _currentZone?.showHighlight();
    _announceCurrent();
  }

  @override
  void autoAssist() {
    // Gently carry the right food to the hungry animal for the child.
    final zone = _currentZone;
    final food = _currentFood;
    if (zone == null || food == null) return;
    food.draggable = false;
    food.snapToZone(zone, onArrived: () => zone.onAccepted?.call(food));
  }
}

/// An animal that is also a drop zone for its food.
class _AnimalZone extends DropZone {
  _AnimalZone({
    required this.kind,
    required super.position,
    required super.size,
    required void Function(_AnimalZone zone, DraggableItem food) onFed,
  }) : super(zoneId: kind.foodId) {
    acceptTest = (item) => !fed && item.itemId == kind.foodId;
    onAccepted = (food) {
      if (fed) return;
      fed = true;
      _eatTime = 1.2;
      onFed(this, food);
    };
  }

  final AnimalKind kind;
  bool fed = false;

  double _time = 0;
  double _eatTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_eatTime > 0) _eatTime = math.max(0, _eatTime - dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final eating = _eatTime > 0;
    final mouthOpen =
        eating ? (math.sin(_time * 2 * math.pi / 0.3).abs()) : 0.0;
    final bounce = fed && !eating
        ? math.sin(_time * 2 * math.pi / 1.4) * 3
        : math.sin(_time * 2 * math.pi / 2.2) * 2;
    AnimalArt.paintAnimal(
      canvas,
      size,
      kind,
      mouthOpen: mouthOpen,
      bounce: bounce,
    );
  }
}

/// Soft farm backdrop: hills, fence, sun. Pure decoration, zero interaction.
class _FarmBackground extends PositionComponent {
  _FarmBackground({required Vector2 size})
      : super(size: size, priority: -10);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sceneImage = GameImages.scene('scene_farm');
    if (sceneImage != null) {
      GameImages.drawCover(sceneImage, canvas, Size(size.x, size.y));
      return;
    }
    final w = size.x;
    final h = size.y;

    // Sun.
    canvas.drawCircle(Offset(w * 0.88, h * 0.14), 46,
        Paint()..color = Palette.butter.withValues(alpha: 0.9));

    // Rolling hills.
    canvas.drawOval(Rect.fromLTWH(-w * 0.25, h * 0.42, w * 0.95, h),
        Paint()..color = Palette.meadow);
    canvas.drawOval(Rect.fromLTWH(w * 0.35, h * 0.48, w * 0.95, h),
        Paint()..color = Palette.softGreen.withValues(alpha: 0.9));

    // Fence.
    final fence = Paint()
      ..color = Palette.softBrown.withValues(alpha: 0.65)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    for (var x = w * 0.08; x < w * 0.95; x += w * 0.12) {
      canvas.drawLine(Offset(x, h * 0.52), Offset(x, h * 0.62), fence);
    }
    canvas.drawLine(
        Offset(w * 0.04, h * 0.555), Offset(w * 0.96, h * 0.555), fence);
  }
}
