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
import '../../shared/components/swipe_clean_layer.dart';
import '../../shared/components/tap_target.dart';
import '../../shared/game/toddler_game.dart';
import 'pig_art.dart';

/// Mini-game: Muddy Pig Bath.
///
/// A big smiling pig played in the mud; the child helps with a gentle wash
/// routine: (1) scrub the mud away by swiping, (2) rinse by tapping the
/// water bucket, (3) dry by dragging the towel onto the pig. The stage
/// decides how many steps the child performs ([StageConfig.routineStepCount]
/// clamped to 1..3); the remaining steps play themselves with the same
/// little animations and voices, so every child sees the full story.
class MuddyPigGame extends ToddlerGame {
  MuddyPigGame(super.gameContext);

  _BathStep _step = _BathStep.intro;

  late _PigComponent _pig;
  SwipeCleanLayer? _mudLayer;
  _SpongeComponent? _sponge;
  GlowHighlight? _mudGlow;
  TapTarget? _bucket;
  DraggableItem? _towel;
  DropZone? _pigZone;

  bool _scrubbed = false;
  bool _rinsed = false;
  bool _dried = false;
  bool _autoScrubbing = false;

  /// How many routine steps the child performs herself (1..3).
  int get _childSteps => stage.routineStepCount.clamp(1, 3);

  @override
  Color backgroundColor() => Palette.skyDay;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final pigSize = Vector2.all(260 * stage.itemScale);
    final pigCenter = Vector2(size.x * 0.5, size.y * 0.5);

    await add(_BathBackground(
      size: size.clone(),
      puddleCenter: Vector2(pigCenter.x, pigCenter.y + pigSize.y * 0.44),
      puddleWidth: pigSize.x * 1.25,
    ));

    _pig = _PigComponent(
      position: pigCenter,
      size: pigSize,
      reducedMotion: reducedMotion,
    );
    await add(_pig);

    // The pig is also the destination for the towel in step 3.
    _pigZone = DropZone(
      zoneId: 'towel',
      position: pigCenter.clone(),
      size: pigSize * 0.9,
      enabled: false,
      priority: 6,
    )..onAccepted = (_) => _onToweled();
    await add(_pigZone!);

    await addMilo();
    say(VoiceInstruction.pigIntro);
    add(TimerComponent(period: 2.4, removeOnFinish: true, onTick: _startScrub));
  }

  // ------------------------------------------------------- Step 1: scrub

  void _startScrub() {
    if (isCompleted) return;
    _step = _BathStep.scrub;
    final layerSize = Vector2(_pig.size.x * 0.96, _pig.size.y * 0.78);
    final layer = SwipeCleanLayer(
      position: _pig.position - layerSize / 2,
      size: layerSize,
      blobCount: 12,
      blobColor: Palette.softBrown,
      eraseRadius: 64,
      onCleaned: _onScrubbed,
      onScrubStart: _showSponge,
      onScrubMove: _moveSponge,
      onScrubEnd: _hideSponge,
    );
    _mudLayer = layer;
    add(layer);
    say(VoiceInstruction.pigScrub);
    startHintCountdown();
  }

  // The sponge lives inside the mud layer, so the scrub-hook coordinates
  // (local to the layer) can be used directly.
  void _showSponge(Vector2 local) {
    final layer = _mudLayer;
    if (layer == null || !layer.isMounted) return;
    var sponge = _sponge;
    if (sponge == null || !sponge.isMounted) {
      sponge = _SpongeComponent(size: Vector2(96, 70) * stage.itemScale);
      _sponge = sponge;
      layer.add(sponge);
    }
    sponge.position = local;
  }

  void _moveSponge(Vector2 local) => _sponge?.position = local;

  void _hideSponge() {
    _sponge?.removeFromParent();
    _sponge = null;
  }

  void _onScrubbed() {
    if (_scrubbed || isCompleted) return;
    _scrubbed = true;
    registerCorrectAction();
    playEffect(SoundEffect.sparkle);
    _hideSponge();
    _mudGlow?.dismiss();
    _mudGlow = null;
    add(SparkleBurst(
      at: _pig.position.clone(),
      reducedMotion: reducedMotion,
      count: 12,
    ));
    _pig.wiggle();
    milo?.laugh();
    add(TimerComponent(
      period: 0.7,
      removeOnFinish: true,
      onTick: () {
        _mudLayer?.removeFromParent();
        _mudLayer = null;
      },
    ));
    add(TimerComponent(period: 1.5, removeOnFinish: true, onTick: _startRinse));
  }

  // ------------------------------------------------------- Step 2: rinse

  void _startRinse() {
    if (isCompleted) return;
    _step = _BathStep.rinse;
    final childDoes = _childSteps >= 2;
    final bucket = TapTarget(
      targetId: 'bucket',
      position: Vector2(
        gameContext.leftHanded ? size.x * 0.15 : size.x * 0.85,
        size.y * 0.58,
      ),
      size: Vector2(150, 150) * stage.itemScale,
      paintItem: PigArt.paintBucket,
      enabled: childDoes,
      onPressed: (_) => _pourBucket(childAction: true),
    );
    _bucket = bucket;
    _popIn(bucket);
    add(bucket);
    say(VoiceInstruction.pigRinse);
    if (childDoes) {
      resetHintCountdown();
    } else {
      stopHintCountdown();
      add(TimerComponent(
        period: 1.8,
        removeOnFinish: true,
        onTick: () => _pourBucket(childAction: false),
      ));
    }
  }

  void _pourBucket({required bool childAction}) {
    if (_step != _BathStep.rinse || _rinsed || isCompleted) return;
    _rinsed = true;
    if (childAction) registerCorrectAction();
    stopHintCountdown();

    final bucket = _bucket;
    if (bucket != null) {
      bucket.enabled = false;
      bucket.hideHighlight();
      if (!reducedMotion) {
        // Tip the bucket towards the pig, then set it back down.
        final tilt = bucket.position.x > _pig.position.x ? -0.55 : 0.55;
        bucket.add(SequenceEffect([
          RotateEffect.by(
            tilt,
            EffectController(duration: 0.3, curve: Curves.easeOut),
          ),
          RotateEffect.by(
            -tilt,
            EffectController(
              duration: 0.35,
              curve: Curves.easeInOut,
              startDelay: 0.8,
            ),
          ),
        ]));
      }
    }
    playEffect(SoundEffect.waterSplash);
    _rainOverPig();
    add(TimerComponent(
      period: 1.1,
      removeOnFinish: true,
      onTick: () {
        _pig.shakeOff();
        add(SparkleBurst(
          at: _pig.position.clone(),
          color: Palette.babyBlue,
          reducedMotion: reducedMotion,
        ));
      },
    ));
    add(TimerComponent(period: 2.0, removeOnFinish: true, onTick: _dismissBucket));
    add(TimerComponent(period: 2.6, removeOnFinish: true, onTick: _startDry));
  }

  /// A handful of gentle water droplets falling over the pig.
  void _rainOverPig() {
    if (reducedMotion) {
      add(SparkleBurst(
        at: _pig.position.clone(),
        color: Palette.babyBlue,
        reducedMotion: true,
      ));
      return;
    }
    final random = math.Random();
    final top = _pig.position.y - _pig.size.y * 0.55;
    for (var i = 0; i < 10; i++) {
      final drop = CircleComponent(
        radius: 5 + random.nextDouble() * 4,
        position: Vector2(
          _pig.position.x + (random.nextDouble() - 0.5) * _pig.size.x * 0.9,
          top - random.nextDouble() * 30,
        ),
        anchor: Anchor.center,
        priority: 30,
        paint: Paint()..color = Palette.babyBlue.withValues(alpha: 0.85),
      );
      drop.add(MoveByEffect(
        Vector2(
          (random.nextDouble() - 0.5) * 14,
          _pig.size.y * (0.5 + random.nextDouble() * 0.35),
        ),
        EffectController(
          duration: 0.55 + random.nextDouble() * 0.35,
          curve: Curves.easeIn,
          startDelay: random.nextDouble() * 0.5,
        ),
        onComplete: () => drop.add(OpacityEffect.fadeOut(
          EffectController(duration: 0.2),
          onComplete: drop.removeFromParent,
        )),
      ));
      add(drop);
    }
  }

  void _dismissBucket() {
    final bucket = _bucket;
    _bucket = null;
    if (bucket == null || !bucket.isMounted) return;
    if (reducedMotion) {
      bucket.removeFromParent();
      return;
    }
    bucket.add(ScaleEffect.to(
      Vector2.all(0.05),
      EffectController(duration: 0.3, curve: Curves.easeIn),
      onComplete: bucket.removeFromParent,
    ));
  }

  // --------------------------------------------------------- Step 3: dry

  void _startDry() {
    if (isCompleted) return;
    _step = _BathStep.dry;
    final childDoes = _childSteps >= 3;
    final towel = DraggableItem(
      itemId: 'towel',
      position: Vector2(
        gameContext.leftHanded ? size.x * 0.17 : size.x * 0.83,
        size.y * 0.78,
      ),
      size: Vector2(170, 120) * stage.itemScale,
      paintItem: PigArt.paintTowel,
      draggable: childDoes,
    );
    _towel = towel;
    _popIn(towel);
    add(towel);
    _pigZone?.enabled = true;
    say(VoiceInstruction.pigDry);
    if (childDoes) {
      resetHintCountdown();
    } else {
      add(TimerComponent(period: 1.8, removeOnFinish: true, onTick: _autoDry));
    }
  }

  void _autoDry() {
    final towel = _towel;
    final zone = _pigZone;
    if (_step != _BathStep.dry || _dried || towel == null || zone == null) {
      return;
    }
    towel.draggable = false;
    towel.snapToZone(zone, onArrived: () => zone.onAccepted?.call(towel));
  }

  void _onToweled() {
    if (_dried || isCompleted) return;
    _dried = true;
    if (_childSteps >= 3) registerCorrectAction();
    stopHintCountdown();
    _pigZone?.enabled = false;
    _pigZone?.hideHighlight();
    playEffect(SoundEffect.chimeSoft);
    _towel?.removeFromParent();
    _towel = null;

    // Brief cosy towel-wrap moment before the clean dance.
    final wrap = _TowelWrap(
      position: Vector2(_pig.position.x, _pig.position.y + _pig.size.y * 0.06),
      size: Vector2(_pig.size.x * 1.02, _pig.size.y * 0.42),
    );
    _popIn(wrap);
    add(wrap);
    add(TimerComponent(
      period: 1.2,
      removeOnFinish: true,
      onTick: () {
        wrap.removeFromParent();
        _celebrateCleanPig();
      },
    ));
  }

  void _celebrateCleanPig() {
    _step = _BathStep.done;
    playEffect(SoundEffect.sparkle);
    _pig.dance();
    add(SparkleBurst(
      at: _pig.position.clone(),
      count: 14,
      reducedMotion: reducedMotion,
    ));
    add(TimerComponent(
      period: 1.1,
      removeOnFinish: true,
      onTick: () => add(SparkleBurst(
        at: Vector2(_pig.position.x, _pig.position.y - _pig.size.y * 0.3),
        color: Palette.babyBlue,
        reducedMotion: reducedMotion,
      )),
    ));
    add(TimerComponent(
      period: 2.3,
      removeOnFinish: true,
      onTick: () => completeGame(voice: VoiceInstruction.pigClean),
    ));
  }

  // -------------------------------------------------------------- Helpers

  void _popIn(PositionComponent component) {
    if (reducedMotion) return;
    component.scale = Vector2.all(0.2);
    component.add(GentleEffects.popIn());
  }

  void _pointMiloAt(Vector2 target) {
    final miloComponent = milo;
    if (miloComponent == null) return;
    miloComponent.pointTowards(target.x >= miloComponent.position.x ? 1 : -1);
  }

  /// Soft glow over the muddy patch (hint for step 1).
  void _glowMudArea() {
    final layer = _mudLayer;
    if (layer == null || !layer.isMounted) return;
    if (_mudGlow == null || !_mudGlow!.isMounted) {
      _mudGlow = GlowHighlight(radius: layer.size.y * 0.5);
      layer.add(_mudGlow!..position = Vector2(layer.size.x / 2, layer.size.y / 2));
    }
    add(TimerComponent(
      period: 2.6,
      removeOnFinish: true,
      onTick: () {
        _mudGlow?.dismiss();
        _mudGlow = null;
      },
    ));
  }

  /// Briefly highlight the pig as the towel destination (hint for step 3).
  void _flashPigZone() {
    final zone = _pigZone;
    if (zone == null) return;
    zone.showHighlight();
    add(TimerComponent(
      period: 2.6,
      removeOnFinish: true,
      onTick: zone.hideHighlight,
    ));
  }

  // ------------------------------------------------------ Hint framework

  @override
  void showHint() {
    switch (_step) {
      case _BathStep.scrub:
        say(VoiceInstruction.pigScrub);
        _glowMudArea();
        _pointMiloAt(_pig.position);
      case _BathStep.rinse:
        say(VoiceInstruction.pigRinse);
        final bucket = _bucket;
        if (bucket != null) {
          bucket.pulse();
          _pointMiloAt(bucket.position);
        }
      case _BathStep.dry:
        say(VoiceInstruction.pigDry);
        final towel = _towel;
        if (towel != null) {
          if (reducedMotion) {
            _flashPigZone();
          } else {
            towel.add(GentleEffects.attentionPulse());
          }
          _pointMiloAt(towel.position);
        }
      case _BathStep.intro:
      case _BathStep.done:
        break;
    }
  }

  @override
  void repeatInstruction() {
    switch (_step) {
      case _BathStep.intro:
        say(VoiceInstruction.pigIntro);
      case _BathStep.scrub:
        say(VoiceInstruction.pigScrub);
      case _BathStep.rinse:
        say(VoiceInstruction.pigRinse);
      case _BathStep.dry:
        say(VoiceInstruction.pigDry);
      case _BathStep.done:
        break;
    }
  }

  @override
  void highlightTarget() {
    switch (_step) {
      case _BathStep.scrub:
        say(VoiceInstruction.pigScrub);
        _glowMudArea();
      case _BathStep.rinse:
        say(VoiceInstruction.pigRinse);
        _bucket?.showHighlight();
      case _BathStep.dry:
        say(VoiceInstruction.pigDry);
        _flashPigZone();
      case _BathStep.intro:
      case _BathStep.done:
        break;
    }
  }

  @override
  void autoAssist() {
    switch (_step) {
      case _BathStep.scrub:
        _autoScrub();
      case _BathStep.rinse:
        _pourBucket(childAction: false);
      case _BathStep.dry:
        _autoDry();
      case _BathStep.intro:
      case _BathStep.done:
        break;
    }
  }

  /// Finishes the scrub for the child: a sponge sweeps across the pig on
  /// its own, then the mud lifts away in a sparkle.
  void _autoScrub() {
    final layer = _mudLayer;
    if (_step != _BathStep.scrub ||
        _scrubbed ||
        _autoScrubbing ||
        layer == null ||
        !layer.isMounted) {
      return;
    }
    _autoScrubbing = true;
    if (reducedMotion) {
      _mudLayer = null;
      layer.removeFromParent();
      _onScrubbed();
      return;
    }
    _hideSponge();
    final sponge = _SpongeComponent(size: Vector2(96, 70) * stage.itemScale)
      ..position = Vector2(layer.size.x * 0.16, layer.size.y * 0.28);
    layer.add(sponge);
    playEffect(SoundEffect.waterSplash);
    sponge.add(SequenceEffect([
      MoveToEffect(
        Vector2(layer.size.x * 0.84, layer.size.y * 0.32),
        EffectController(duration: 0.45, curve: Curves.easeInOut),
      ),
      MoveToEffect(
        Vector2(layer.size.x * 0.18, layer.size.y * 0.55),
        EffectController(duration: 0.45, curve: Curves.easeInOut),
      ),
      MoveToEffect(
        Vector2(layer.size.x * 0.82, layer.size.y * 0.78),
        EffectController(duration: 0.45, curve: Curves.easeInOut),
      ),
    ]));
    add(TimerComponent(
      period: 1.5,
      removeOnFinish: true,
      onTick: () {
        if (_scrubbed) return; // The child finished it herself meanwhile.
        _mudLayer = null;
        layer.removeFromParent();
        _onScrubbed();
      },
    ));
  }
}

/// The three routine steps plus the intro/outro moments.
enum _BathStep { intro, scrub, rinse, dry, done }

/// The big smiling pig. Idles with a tiny breathing bounce and owns its
/// happy reactions (wiggle, shake-off, clean dance).
class _PigComponent extends PositionComponent {
  _PigComponent({
    required Vector2 position,
    required Vector2 size,
    required this.reducedMotion,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
          priority: 5,
        );

  final bool reducedMotion;

  /// After the bath the eyes switch to delighted arcs.
  bool happy = false;

  double _time = 0;

  /// Small happy wobble after the mud comes off.
  void wiggle() {
    if (reducedMotion) return;
    add(GentleEffects.wobble(angle: 0.05, repeats: 2));
  }

  /// Quick little left-right shake after the rinse.
  void shakeOff() {
    if (reducedMotion) return;
    add(GentleEffects.wobble(angle: 0.09, repeats: 3));
  }

  /// The funny clean dance: hops and wiggles for about two seconds.
  void dance() {
    happy = true;
    if (reducedMotion) return;
    add(SequenceEffect([
      GentleEffects.happyHop(height: 26),
      GentleEffects.happyHop(height: 20),
      GentleEffects.wobble(angle: 0.07, repeats: 2),
      GentleEffects.happyHop(height: 24),
    ]));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final bounce =
        reducedMotion ? 0.0 : math.sin(_time * 2 * math.pi / 2.4) * 3;
    PigArt.paintPig(canvas, size, happy: happy, bounce: bounce);
  }
}

/// The sponge that follows the child's finger while scrubbing.
class _SpongeComponent extends PositionComponent {
  _SpongeComponent({required Vector2 size})
      : super(size: size, anchor: Anchor.center, priority: 40);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    PigArt.paintSponge(canvas, size);
  }
}

/// Short-lived cosy towel band shown over the pig after drying.
class _TowelWrap extends PositionComponent {
  _TowelWrap({required Vector2 position, required Vector2 size})
      : super(
          position: position,
          size: size,
          anchor: Anchor.center,
          priority: 30,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    PigArt.paintTowelWrap(canvas, size);
  }
}

/// Soft outdoor bath corner: sun, clouds, meadow, bushes, flowers and a
/// shallow puddle under the pig. Pure decoration, zero interaction.
class _BathBackground extends PositionComponent {
  _BathBackground({
    required Vector2 size,
    required this.puddleCenter,
    required this.puddleWidth,
  }) : super(size: size, priority: -10);

  final Vector2 puddleCenter;
  final double puddleWidth;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;

    // Sun with a soft halo.
    canvas.drawCircle(Offset(w * 0.88, h * 0.13), 54,
        Paint()..color = Palette.butter.withValues(alpha: 0.35));
    canvas.drawCircle(Offset(w * 0.88, h * 0.13), 42,
        Paint()..color = Palette.butter.withValues(alpha: 0.9));

    // Drifting clouds.
    final cloud = Paint()..color = Palette.cream.withValues(alpha: 0.9);
    for (final c in [Offset(w * 0.18, h * 0.13), Offset(w * 0.5, h * 0.09)]) {
      canvas.drawOval(
          Rect.fromCenter(center: c, width: w * 0.14, height: h * 0.07), cloud);
      canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(w * 0.05, h * 0.02),
              width: w * 0.12,
              height: h * 0.06),
          cloud);
      canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(-w * 0.05, h * 0.025),
              width: w * 0.10,
              height: h * 0.05),
          cloud);
    }

    // Rolling meadow.
    canvas.drawOval(Rect.fromLTWH(-w * 0.3, h * 0.5, w * 1.1, h * 0.9),
        Paint()..color = Palette.meadow);
    canvas.drawOval(Rect.fromLTWH(w * 0.3, h * 0.55, w * 1.0, h * 0.9),
        Paint()..color = Palette.softGreen.withValues(alpha: 0.85));

    // Bushes framing the bath corner.
    final bush = Paint()..color = Palette.mint;
    canvas.drawCircle(Offset(w * 0.05, h * 0.60), w * 0.06, bush);
    canvas.drawCircle(Offset(w * 0.11, h * 0.63), w * 0.05, bush);
    canvas.drawCircle(Offset(w * 0.95, h * 0.62), w * 0.06, bush);

    // Shallow bath puddle under the pig with a couple of soap bubbles.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(puddleCenter.x, puddleCenter.y),
        width: puddleWidth,
        height: puddleWidth * 0.2,
      ),
      Paint()..color = Palette.babyBlue.withValues(alpha: 0.55),
    );
    final bubble = Paint()..color = Palette.cream.withValues(alpha: 0.8);
    canvas.drawCircle(
        Offset(puddleCenter.x - puddleWidth * 0.42, puddleCenter.y - 12), 9,
        bubble);
    canvas.drawCircle(
        Offset(puddleCenter.x + puddleWidth * 0.45, puddleCenter.y - 6), 7,
        bubble);

    // A few tiny meadow flowers.
    for (final f in [
      Offset(w * 0.14, h * 0.80),
      Offset(w * 0.86, h * 0.86),
      Offset(w * 0.25, h * 0.92),
      Offset(w * 0.78, h * 0.70),
    ]) {
      final petal = Paint()..color = Palette.blush;
      for (var i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        canvas.drawCircle(
          f.translate(math.cos(angle) * 6, math.sin(angle) * 6),
          4.5,
          petal,
        );
      }
      canvas.drawCircle(f, 3.5, Paint()..color = Palette.butter);
    }
  }
}
