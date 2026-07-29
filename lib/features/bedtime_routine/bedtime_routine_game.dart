import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../core/audio/sound_effects.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/theme/palette.dart';
import '../../shared/characters/milo_state.dart';
import '../../shared/components/draggable_item.dart';
import '../../shared/components/drop_zone.dart';
import '../../shared/components/gentle_effects.dart';
import '../../shared/components/tap_target.dart';
import '../../shared/game/toddler_game.dart';
import 'bedtime_art.dart';

/// Mini-game: Bedtime Routine.
///
/// Milo's cosy bedroom at dusk. The routine always runs in the same gentle
/// order — toy into the basket, brush teeth, pyjamas on, teddy into bed,
/// light off — and the development stage decides which steps the child
/// performs; Milo does the remaining ones by himself with a slow little
/// animation and the step's voice line, so the full ritual is always seen.
///
/// This is deliberately the calmest, sleepiest activity in the game: no
/// hurry, no wrong answers beyond a soft drift back home, and it ends with
/// the room dimming, stars appearing one by one and Milo falling asleep.
class BedtimeRoutineGame extends ToddlerGame {
  BedtimeRoutineGame(super.gameContext);

  final List<_RoutineStep> _steps = [];
  int _current = 0;

  DropZone? _basketZone;
  DropZone? _teethZone;
  DropZone? _pajamaZone;
  DropZone? _bedZone;
  _LampTarget? _lamp;

  late Rect _windowRect;
  Vector2 _miloFace = Vector2.zero();
  Vector2 _miloBody = Vector2.zero();
  Vector2 _teddyRest = Vector2.zero();

  @override
  Color backgroundColor() => Palette.cream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final w = size.x;
    final h = size.y;
    final s = stage.itemScale;

    // ------------------------------------------------------ Scene layout
    _windowRect = Rect.fromLTWH(w * 0.07, h * 0.10, w * 0.26, h * 0.40);
    final bedRect = Rect.fromLTWH(w * 0.58, h * 0.46, w * 0.37, h * 0.34);
    final pillowCenter = Offset(
      bedRect.right - bedRect.width * 0.20,
      bedRect.top + bedRect.height * 0.18,
    );
    final standRect = Rect.fromLTWH(w * 0.455, h * 0.62, w * 0.09, h * 0.16);
    _teddyRest =
        Vector2(pillowCenter.dx, pillowCenter.dy - bedRect.height * 0.04);

    await add(_BedroomBackground(
      size: size.clone(),
      windowRect: _windowRect,
      bedRect: bedRect,
      pillowCenter: pillowCenter,
      standRect: standRect,
    ));

    // Milo stands right beside his bed.
    const miloHeight = 158.0;
    final miloX = w * 0.72;
    await addMilo(position: Vector2(miloX, h - 6), height: miloHeight);
    _miloFace = Vector2(miloX, h - 6 - miloHeight * 0.72);
    _miloBody = Vector2(miloX, h - 6 - miloHeight * 0.36);

    // ------------------------------------------------------- Drop zones
    _basketZone = DropZone(
      zoneId: 'toy_basket',
      position: Vector2(w * 0.12, h * 0.75),
      size: Vector2(176, 148) * s,
      paintZone: BedtimeArt.paintBasket,
      acceptTest: (item) => _wants(_StepKind.toy, item),
      onAccepted: _onToyDone,
    );
    // The two Milo zones sit above him (priority) so their hint glow is
    // visible; both accept whichever Milo-directed item is current, which
    // keeps "aim roughly at Milo" forgiving for toddler fingers.
    _teethZone = DropZone(
      zoneId: 'milo_teeth',
      position: _miloFace.clone(),
      size: Vector2.all(112 * s),
      priority: 55,
      acceptTest: _acceptsOnMilo,
      onAccepted: _onMiloZoneAccepted,
    );
    _pajamaZone = DropZone(
      zoneId: 'milo_pajamas',
      position: _miloBody.clone(),
      size: Vector2.all(124 * s),
      priority: 55,
      acceptTest: _acceptsOnMilo,
      onAccepted: _onMiloZoneAccepted,
    );
    _bedZone = DropZone(
      zoneId: 'bed',
      position: Vector2(
        pillowCenter.dx - bedRect.width * 0.06,
        pillowCenter.dy + bedRect.height * 0.12,
      ),
      size: Vector2(190, 150) * s,
      acceptTest: (item) => _wants(_StepKind.teddy, item),
      onAccepted: _onTeddyDone,
    );
    await addAll([_basketZone!, _teethZone!, _pajamaZone!, _bedZone!]);

    // ------------------------------------------------------------- Lamp
    final lampSize = Vector2(112, 144) * s;
    _lamp = _LampTarget(
      position: Vector2(standRect.center.dx, standRect.top - lampSize.y / 2 + 6),
      size: lampSize,
      onPressed: _onLampPressed,
    );
    await add(_lamp!);

    // ------------------- Items: visible from the start, inert until due
    final rowY = h * 0.885;
    final toy = _makeItem(
        'toy', Vector2(w * 0.27, rowY), Vector2.all(106 * s), BedtimeArt.paintToy);
    final brush = _makeItem('toothbrush', Vector2(w * 0.38, rowY),
        Vector2(104, 136) * s, BedtimeArt.paintToothbrush);
    final pajamas = _makeItem('pajamas', Vector2(w * 0.485, rowY),
        Vector2(128, 114) * s, BedtimeArt.paintPajamas);
    final teddy = _makeItem('teddy', Vector2(w * 0.585, rowY),
        Vector2(116, 130) * s, BedtimeArt.paintTeddy);
    await addAll([toy, brush, pajamas, teddy]);

    _buildSteps(toy: toy, brush: brush, pajamas: pajamas, teddy: teddy);

    say(VoiceInstruction.bedtimeIntro,
        talkFor: const Duration(milliseconds: 2400));
    add(TimerComponent(
      period: 2.6,
      removeOnFinish: true,
      onTick: () => _beginStep(0),
    ));
  }

  DraggableItem _makeItem(String id, Vector2 position, Vector2 itemSize,
          void Function(Canvas, Vector2) paint) =>
      DraggableItem(
        itemId: id,
        position: position,
        size: itemSize,
        draggable: false,
        paintItem: paint,
      );

  void _buildSteps({
    required DraggableItem toy,
    required DraggableItem brush,
    required DraggableItem pajamas,
    required DraggableItem teddy,
  }) {
    final n = stage.routineStepCount.clamp(1, 5);
    final Set<_StepKind> childKinds;
    if (n >= 5) {
      // Little Thinker: the whole routine.
      childKinds = _StepKind.values.toSet();
    } else if (n <= 1) {
      // Explorer: only tucking teddy in; Milo does the rest.
      childKinds = {_StepKind.teddy};
    } else {
      // Helper: toy away, teddy in bed and light off.
      childKinds = {_StepKind.toy, _StepKind.teddy, _StepKind.light};
    }

    _steps
      ..clear()
      ..addAll([
        _RoutineStep(_StepKind.toy, VoiceInstruction.bedtimeToys,
            byChild: childKinds.contains(_StepKind.toy),
            item: toy,
            zone: _basketZone),
        _RoutineStep(_StepKind.teeth, VoiceInstruction.bedtimeTeeth,
            byChild: childKinds.contains(_StepKind.teeth),
            item: brush,
            zone: _teethZone),
        _RoutineStep(_StepKind.pajamas, VoiceInstruction.bedtimePajamas,
            byChild: childKinds.contains(_StepKind.pajamas),
            item: pajamas,
            zone: _pajamaZone),
        _RoutineStep(_StepKind.teddy, VoiceInstruction.bedtimeTeddy,
            byChild: childKinds.contains(_StepKind.teddy),
            item: teddy,
            zone: _bedZone),
        _RoutineStep(_StepKind.light, VoiceInstruction.bedtimeLight,
            byChild: childKinds.contains(_StepKind.light)),
      ]);
  }

  // ------------------------------------------------------- Step control

  _RoutineStep? get _currentStep =>
      _current < _steps.length ? _steps[_current] : null;

  /// True when [item] is exactly what the current, unfinished step needs.
  bool _wants(_StepKind kind, DraggableItem item) {
    final step = _currentStep;
    return step != null &&
        !step.done &&
        step.kind == kind &&
        identical(step.item, item);
  }

  bool _acceptsOnMilo(DraggableItem item) =>
      _wants(_StepKind.teeth, item) || _wants(_StepKind.pajamas, item);

  void _onMiloZoneAccepted(DraggableItem item) {
    if (_currentStep?.kind == _StepKind.teeth) {
      _onTeethDone(item);
    } else {
      _onPajamasDone(item);
    }
  }

  void _beginStep(int index) {
    if (isCompleted || index >= _steps.length) return;
    _current = index;
    final step = _steps[index];
    say(step.voice);
    if (step.byChild) {
      if (step.kind == _StepKind.light) {
        _lamp?.enabled = true;
      } else {
        step.item?.draggable = true;
      }
      startHintCountdown();
    } else {
      // Milo does this one himself; no hints while the child just watches.
      stopHintCountdown();
      add(TimerComponent(
        period: reducedMotion ? 0.8 : 1.6,
        removeOnFinish: true,
        onTick: () => _autoPlay(step),
      ));
    }
  }

  /// Plays a non-child step: the item floats gently to its place (or the
  /// lamp winks out) exactly as if the child had done it.
  void _autoPlay(_RoutineStep step) {
    if (isCompleted || step.done) return;
    if (step.kind == _StepKind.light) {
      _lamp?.pulse();
      add(TimerComponent(
        period: reducedMotion ? 0.4 : 1.1,
        removeOnFinish: true,
        onTick: _turnOffLight,
      ));
      return;
    }
    final item = step.item;
    final zone = step.zone;
    if (item == null || zone == null) return;
    item.draggable = false;
    playEffect(SoundEffect.slide);
    item.add(
      SequenceEffect(
        [
          MoveByEffect(
            Vector2(0, -14),
            EffectController(
                duration: reducedMotion ? 0.1 : 0.3, curve: Curves.easeOut),
          ),
          MoveToEffect(
            zone.position.clone(),
            EffectController(
                duration: reducedMotion ? 0.25 : 1.0, curve: Curves.easeInOut),
          ),
        ],
        onComplete: () {
          playEffect(SoundEffect.ding);
          zone.onAccepted?.call(item);
        },
      ),
    );
  }

  /// Marks the current step done if it matches [kind]; null when it was
  /// already handled (guards double drops / repeated timers).
  _RoutineStep? _take(_StepKind kind) {
    final step = _currentStep;
    if (step == null || step.kind != kind || step.done) return null;
    step.done = true;
    return step;
  }

  void _celebrateStep({required Vector2 at, bool miloCheers = true}) {
    add(SparkleBurst(at: at.clone(), reducedMotion: reducedMotion, count: 8));
    registerCorrectAction();
    if (miloCheers) {
      milo?.celebrate(duration: const Duration(milliseconds: 1100));
    }
  }

  void _advance({double? delay}) {
    final next = _current + 1;
    add(TimerComponent(
      period: delay ?? (reducedMotion ? 0.9 : 1.7),
      removeOnFinish: true,
      onTick: () => _beginStep(next),
    ));
  }

  // --------------------------------------------------- Step completions

  void _onToyDone(DraggableItem item) {
    final step = _take(_StepKind.toy);
    if (step == null) return;
    item.draggable = false;
    // The toy settles snugly down into the basket.
    item.add(ScaleEffect.to(
      Vector2.all(0.72),
      EffectController(
          duration: reducedMotion ? 0.15 : 0.4, curve: Curves.easeInOut),
    ));
    item.add(MoveByEffect(
      Vector2(0, 10),
      EffectController(
          duration: reducedMotion ? 0.15 : 0.4, curve: Curves.easeInOut),
    ));
    _celebrateStep(at: _basketZone!.position);
    _advance();
  }

  void _onTeethDone(DraggableItem item) {
    final step = _take(_StepKind.teeth);
    if (step == null) return;
    item
      ..draggable = false
      ..priority = 60; // visible in front of Milo while brushing
    final effects = <Effect>[
      MoveToEffect(
        _miloFace + Vector2(6, -6),
        EffectController(
            duration: reducedMotion ? 0.1 : 0.2, curve: Curves.easeOut),
      ),
      if (!reducedMotion) ...[
        // A quick soft brush wiggle by Milo's cheek.
        RotateEffect.by(0.3, EffectController(duration: 0.1)),
        for (var i = 0; i < 3; i++) ...[
          RotateEffect.by(-0.6, EffectController(duration: 0.14)),
          RotateEffect.by(0.6, EffectController(duration: 0.14)),
        ],
        RotateEffect.by(-0.3, EffectController(duration: 0.1)),
      ],
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(
            duration: reducedMotion ? 0.2 : 0.45, curve: Curves.easeIn),
      ),
    ];
    item.add(SequenceEffect(effects, onComplete: item.removeFromParent));
    _celebrateStep(at: _miloFace);
    _advance(delay: reducedMotion ? 0.9 : 2.1);
  }

  void _onPajamasDone(DraggableItem item) {
    final step = _take(_StepKind.pajamas);
    if (step == null) return;
    item
      ..draggable = false
      ..priority = 60;
    playEffect(SoundEffect.sparkle);
    // The shirt melts onto Milo in a puff of sparkles.
    item.add(
      SequenceEffect(
        [
          MoveToEffect(
            _miloBody.clone(),
            EffectController(
                duration: reducedMotion ? 0.1 : 0.25, curve: Curves.easeOut),
          ),
          ScaleEffect.to(
            Vector2.zero(),
            EffectController(
                duration: reducedMotion ? 0.2 : 0.5, curve: Curves.easeIn),
          ),
        ],
        onComplete: item.removeFromParent,
      ),
    );
    _celebrateStep(at: Vector2(_miloBody.x, _miloBody.y - 24));
    _advance();
  }

  void _onTeddyDone(DraggableItem item) {
    final step = _take(_StepKind.teddy);
    if (step == null) return;
    item.draggable = false;
    // Teddy tips over slightly and settles onto the pillow.
    item.add(RotateEffect.to(
      -0.16,
      EffectController(
          duration: reducedMotion ? 0.15 : 0.5, curve: Curves.easeInOut),
    ));
    item.add(MoveToEffect(
      _teddyRest.clone(),
      EffectController(
          duration: reducedMotion ? 0.15 : 0.5, curve: Curves.easeInOut),
    ));
    _celebrateStep(at: _teddyRest);
    _advance();
  }

  void _onLampPressed(TapTarget _) {
    if (_currentStep?.kind != _StepKind.light) return;
    _turnOffLight();
  }

  /// The final step: light off, room dims, stars come out, Milo yawns and
  /// falls asleep. Ends the game exactly once.
  void _turnOffLight() {
    final step = _take(_StepKind.light);
    if (step == null) return;
    final lamp = _lamp;
    if (lamp != null) {
      lamp
        ..enabled = false
        ..isOn = false
        ..hideHighlight();
      playEffect(SoundEffect.ding);
      add(SparkleBurst(
          at: lamp.position.clone(), reducedMotion: reducedMotion, count: 8));
    }
    registerCorrectAction();
    stopHintCountdown();

    add(_NightOverlay(size: size.clone(), reducedMotion: reducedMotion));
    playEffect(SoundEffect.nightCalm);
    _spawnStars();

    add(TimerComponent(
      period: reducedMotion ? 0.6 : 1.3,
      removeOnFinish: true,
      onTick: () {
        playEffect(SoundEffect.yawn);
        milo?.setState(MiloState.sleepy);
      },
    ));
    add(TimerComponent(
      period: reducedMotion ? 1.8 : 3.4,
      removeOnFinish: true,
      onTick: _finishRoutine,
    ));
  }

  void _finishRoutine() {
    if (isCompleted) return;
    completeGame(voice: VoiceInstruction.bedtimeDone);
    // The sleepiest game keeps Milo dozing instead of a bouncy dance.
    milo?.setState(MiloState.sleepy);
  }

  /// Soft stars pop into the dusk window one by one.
  void _spawnStars() {
    final sky = _windowRect.deflate(_windowRect.width * 0.06);
    const spots = [
      Offset(0.26, 0.20),
      Offset(0.58, 0.14),
      Offset(0.78, 0.36),
      Offset(0.38, 0.44),
      Offset(0.66, 0.60),
      Offset(0.24, 0.62),
    ];
    for (var i = 0; i < spots.length; i++) {
      final at = Vector2(
        sky.left + sky.width * spots[i].dx,
        sky.top + sky.height * spots[i].dy,
      );
      final radius = _windowRect.width * (i.isEven ? 0.045 : 0.036);
      add(TimerComponent(
        period: (reducedMotion ? 0.25 : 0.6) * (i + 1),
        removeOnFinish: true,
        onTick: () => add(_WindowStar(
          position: at,
          radius: radius,
          reducedMotion: reducedMotion,
        )),
      ));
    }
  }

  // ------------------------------------------------------ Hint ladder

  @override
  void showHint() {
    final step = _currentStep;
    if (step == null || !step.byChild || step.done || isCompleted) return;
    final miloX = milo?.position.x ?? size.x / 2;
    if (step.kind == _StepKind.light) {
      final lamp = _lamp;
      if (lamp == null) return;
      lamp
        ..pulse()
        ..showHighlight();
      _hideLater(lamp.hideHighlight);
      milo?.pointTowards(lamp.position.x >= miloX ? 1 : -1);
      return;
    }
    final item = step.item;
    final zone = step.zone;
    if (item == null || zone == null) return;
    if (!reducedMotion) item.add(GentleEffects.attentionPulse());
    zone.showHighlight();
    _hideLater(zone.hideHighlight);
    milo?.pointTowards(item.position.x >= miloX ? 1 : -1);
  }

  void _hideLater(void Function() hide) {
    add(TimerComponent(period: 2.5, removeOnFinish: true, onTick: hide));
  }

  @override
  void repeatInstruction() {
    final step = _currentStep;
    say(step?.voice ?? VoiceInstruction.bedtimeIntro);
  }

  @override
  void highlightTarget() {
    final step = _currentStep;
    if (step == null || !step.byChild || step.done) return;
    if (step.kind == _StepKind.light) {
      _lamp?.showHighlight();
      _hideLater(() => _lamp?.hideHighlight());
    } else {
      step.zone?.showHighlight();
      _hideLater(() => step.zone?.hideHighlight());
    }
    repeatInstruction();
  }

  @override
  void autoAssist() {
    final step = _currentStep;
    if (step == null || !step.byChild || step.done || isCompleted) return;
    if (step.kind == _StepKind.light) {
      _turnOffLight();
      return;
    }
    // Gently carry the current item to its place for the child.
    final item = step.item;
    final zone = step.zone;
    if (item == null || zone == null) return;
    item.draggable = false;
    item.snapToZone(zone, onArrived: () => zone.onAccepted?.call(item));
  }
}

// ---------------------------------------------------------------- Steps

enum _StepKind { toy, teeth, pajamas, teddy, light }

class _RoutineStep {
  _RoutineStep(this.kind, this.voice,
      {required this.byChild, this.item, this.zone});

  final _StepKind kind;
  final VoiceInstruction voice;

  /// Whether the child performs this step (otherwise Milo auto-plays it).
  final bool byChild;
  final DraggableItem? item;
  final DropZone? zone;
  bool done = false;
}

// ----------------------------------------------------------- Components

/// The bedside lamp: a big tap target whose art switches between the warm
/// glowing "on" look and the muted "off" look.
class _LampTarget extends TapTarget {
  _LampTarget({required super.position, required super.size, super.onPressed})
      : super(targetId: 'lamp', enabled: false, priority: 12);

  bool isOn = true;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    BedtimeArt.paintLamp(canvas, size, isOn: isOn, time: _time);
  }
}

/// Pure decoration: Milo's bedroom. Zero interaction.
class _BedroomBackground extends PositionComponent {
  _BedroomBackground({
    required Vector2 size,
    required this.windowRect,
    required this.bedRect,
    required this.pillowCenter,
    required this.standRect,
  }) : super(size: size, priority: -10);

  final Rect windowRect;
  final Rect bedRect;
  final Offset pillowCenter;
  final Rect standRect;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    BedtimeArt.paintRoom(
      canvas,
      size,
      windowRect: windowRect,
      bedRect: bedRect,
      pillowCenter: pillowCenter,
      standRect: standRect,
    );
  }
}

/// A translucent dark-blue veil that fades in very slowly when the light
/// goes out. Never flashes; with reduced motion it settles almost at once.
class _NightOverlay extends PositionComponent {
  _NightOverlay({required Vector2 size, required this.reducedMotion})
      : super(size: size, priority: 60);

  final bool reducedMotion;
  double _elapsed = 0;

  double get _duration => reducedMotion ? 0.4 : 2.6;

  @override
  void update(double dt) {
    super.update(dt);
    if (_elapsed < _duration) _elapsed = math.min(_duration, _elapsed + dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = Curves.easeInOut.transform(math.min(1.0, _elapsed / _duration));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Palette.skyNight.withValues(alpha: 0.45 * t),
    );
  }
}

/// One tiny star in the window, popping in softly and twinkling slowly.
class _WindowStar extends PositionComponent {
  _WindowStar({
    required Vector2 position,
    required double radius,
    required this.reducedMotion,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
          priority: 70,
        );

  final bool reducedMotion;
  double _time = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!reducedMotion) {
      scale = Vector2.zero();
      add(GentleEffects.popIn());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final glow = reducedMotion ? 1.0 : 0.78 + 0.22 * math.sin(_time * 1.9);
    BedtimeArt.paintStar(canvas, size, glow: glow);
  }
}
