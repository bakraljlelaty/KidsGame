import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../../content/items/content_item.dart';
import '../../../content/items/item_catalog.dart';
import '../../../core/audio/sound_effects.dart';
import '../../../core/audio/voice_catalog.dart';
import '../../../core/theme/palette.dart';
import '../../../shared/components/gentle_effects.dart';
import '../../../shared/game/toddler_game.dart';
import '../../../shared/items/item_art.dart';
import 'trace_path_library.dart';

/// TraceShape — finger-trace big soft outlines.
///
/// A guide path (dotted corridor) appears with a pulsing start dot; as the
/// child drags along it the stroke fills with colour. Progress only ever
/// grows: wandering out of the corridor simply pauses it, lifting the
/// finger keeps everything, and the stroke auto-finishes once ~85% is
/// covered. Multi-stroke forms (A, T, 4, 5...) trace stroke by stroke.
///
/// Content: pack 'shapes' / 'numbers' / 'letters' (per app language),
/// filtered by bandConfig.traceDetail (1 = shapes only + extra wide
/// corridor, 2 = + digits, 3 = + letters). Items without an authored path
/// fall back to shapes. Rounds: params['rounds'] (default 2).
class TraceShapeGame extends ToddlerGame {
  TraceShapeGame(super.gameContext);

  static final math.Random _random = math.Random();

  late final int _detail;
  late final List<ContentItem> _order;
  late final int _rounds;

  int _round = 0;
  int _hintStep = 0;
  _TraceBoard? _board;
  _PreviewTile? _preview;
  ContentItem? _item;

  @override
  Color backgroundColor() => Palette.cream;

  double get _corridorRadius {
    final base = switch (_detail) {
      1 => 78.0,
      2 => 62.0,
      _ => 55.0,
    };
    return base * gameContext.bandConfig.itemScale.clamp(1.0, 1.3);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _detail = gameContext
        .param('traceDetail', gameContext.bandConfig.traceDetail)
        .clamp(1, 3);
    _rounds = math.max(1, gameContext.param('rounds', 2));
    _order = _resolveItems();

    await add(_SoftBackground(size: size.clone()));
    await addMilo();
    say(VoiceInstruction.traceIntro);
    add(TimerComponent(
      period: 1.8,
      removeOnFinish: true,
      onTick: _startRound,
    ));
  }

  /// Items that have an authored trace path and are unlocked at this
  /// band's trace detail; falls back to shapes so a round always exists.
  List<ContentItem> _resolveItems() {
    final spec = gameContext.spec;
    var pool = spec == null || spec.contentPack.isEmpty
        ? ItemCatalog.shapes
        : spec.contentPack == 'letters'
            ? ItemCatalog.lettersFor(gameContext.languageCode)
            : ItemCatalog.pack(spec.contentPack);
    if (pool.isEmpty) pool = ItemCatalog.shapes;

    var traceable = pool
        .where((item) =>
            TracePathLibrary.has(item.id) &&
            TracePathLibrary.allowedAtDetail(item.id, _detail))
        .toList();
    if (traceable.isEmpty) {
      traceable = ItemCatalog.shapes
          .where((item) => TracePathLibrary.has(item.id))
          .toList();
    }
    return traceable..shuffle(_random);
  }

  // ------------------------------------------------------------- rounds

  void _startRound() {
    if (isCompleted) return;
    _board?.removeFromParent();
    _preview?.removeFromParent();
    _hintStep = 0;

    final item = _order[_round % _order.length];
    _item = item;
    final path = TracePathLibrary.forItem(item.id) ??
        TracePathLibrary.forItem('shape_circle')!;

    final side =
        math.max(260.0, math.min(size.y * 0.74, size.x * 0.56));
    final board = _TraceBoard(
      item: item,
      tracePath: path,
      corridorRadius: _corridorRadius,
      reducedMotion: reducedMotion,
      highContrast: highContrast,
      position: Vector2(size.x / 2, size.y * 0.46),
      size: Vector2.all(side),
      onStrokeComplete: _onStrokeComplete,
      onItemComplete: _onItemComplete,
      onProgress: resetHintCountdown,
    );
    _board = board;
    add(board);
    if (!reducedMotion) {
      board.scale = Vector2.all(0.6);
      board.add(GentleEffects.popIn());
    }

    final previewSide = 84.0 * gameContext.bandConfig.itemScale;
    final preview = _PreviewTile(
      item: item,
      highContrast: highContrast,
      position: Vector2(
        gameContext.leftHanded ? 24 + previewSide / 2 : size.x - 24 - previewSide / 2,
        24 + previewSide / 2,
      ),
      size: Vector2.all(previewSide),
    );
    _preview = preview;
    add(preview);
    if (!reducedMotion) {
      preview.scale = Vector2.zero();
      preview.add(GentleEffects.popIn());
    }

    say(VoiceInstruction.traceFollow);
    final name = item.nameVoice;
    if (name != null) {
      add(TimerComponent(
        period: 1.3,
        removeOnFinish: true,
        onTick: () => say(name),
      ));
    }
    startHintCountdown();
  }

  void _onStrokeComplete() {
    playEffect(SoundEffect.chimeSoft);
    gameContext.haptics.success();
    registerCorrectAction();
    _hintStep = 0;
  }

  void _onItemComplete() {
    registerCorrectAction();
    stopHintCountdown();
    playEffect(SoundEffect.chimeSuccess);
    milo?.celebrate();
    _board?.celebrate();

    _round += 1;
    if (_round >= _rounds) {
      add(TimerComponent(
        period: 1.6,
        removeOnFinish: true,
        onTick: () => completeGame(voice: VoiceInstruction.greatJob),
      ));
    } else {
      add(TimerComponent(
        period: 2.0,
        removeOnFinish: true,
        onTick: _startRound,
      ));
    }
  }

  // --------------------------------------------------------------- hints

  /// Hints escalate gently on their own so nobody is ever stuck:
  /// pulse the next start dot, then repeat the words, then show a little
  /// dot travelling the remaining path, then fill a bit of it.
  @override
  void showHint() {
    final board = _board;
    if (board == null || isCompleted || board.allDone) return;
    _hintStep += 1;
    board.pulseStartDot();
    milo?.pointTowards(board.position.x >= size.x / 2 ? 1 : -1);
    if (_hintStep == 2) {
      repeatInstruction();
    } else if (_hintStep == 3) {
      highlightTarget();
    } else if (_hintStep >= 4) {
      autoAssist();
    }
  }

  @override
  void repeatInstruction() {
    say(VoiceInstruction.traceFollow);
    final name = _item?.nameVoice;
    if (name != null) {
      add(TimerComponent(
        period: 1.3,
        removeOnFinish: true,
        onTick: () => say(name),
      ));
    }
  }

  @override
  void highlightTarget() => _board?.runGuideDot();

  @override
  void autoAssist() => _board?.assistNextPortion(0.30);
}

// ===================================================================
// Trace board
// ===================================================================

/// The interactive tracing surface: draws the corridor guide, the filled
/// progress stroke, the pulsing start dot and a direction chevron, and
/// consumes drags anywhere on (and generously around) itself.
class _TraceBoard extends PositionComponent
    with DragCallbacks, HasGameReference<TraceShapeGame> {
  _TraceBoard({
    required this.item,
    required this.tracePath,
    required this.corridorRadius,
    required this.reducedMotion,
    required this.highContrast,
    required super.position,
    required Vector2 super.size,
    this.onStrokeComplete,
    this.onItemComplete,
    this.onProgress,
  }) : super(anchor: Anchor.center, priority: 5);

  final ContentItem item;
  final TracePath tracePath;
  final double corridorRadius;
  final bool reducedMotion;
  final bool highContrast;

  final void Function()? onStrokeComplete;
  final void Function()? onItemComplete;
  final void Function()? onProgress;

  static const double _hitPadding = 60;
  static const double _guideWidth = 26;
  static const double _fillWidth = 20;

  /// Margin between the 0..1 path box and the board edge; only needs to
  /// cover the drawn stroke and start dot (the acceptance corridor may
  /// spill past the card — the hit area is padded for that).
  static const double _inset = 38;

  /// Pixel-space strokes, evenly resampled.
  final List<List<Offset>> _strokes = [];

  int _strokeIndex = 0;

  /// Continuous progress along the current stroke, in sample-index units.
  double _fillPos = 0;

  /// While set, update() slides _fillPos towards this index.
  double? _assistTarget;
  double _assistRate = 0;

  bool _finishing = false;
  bool _glowAll = false;
  double _nextMilestone = 0.25;

  double _time = 0;
  double _pulseUntil = -1;

  bool get allDone => _strokeIndex >= _strokes.length;

  List<Offset> get _current => _strokes[_strokeIndex];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final span = math.max(1.0, size.x - _inset * 2);
    for (final normalized in tracePath.strokes) {
      final pixels = [
        for (final p in normalized)
          Offset(_inset + p.dx * span, _inset + p.dy * span),
      ];
      final sampleCount =
          (TracePathLibrary.lengthOf(pixels) / 12).round().clamp(24, 96);
      _strokes.add(TracePathLibrary.resample(pixels, sampleCount));
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= -_hitPadding &&
        point.y >= -_hitPadding &&
        point.x <= size.x + _hitPadding &&
        point.y <= size.y + _hitPadding;
  }

  // -------------------------------------------------------- interaction

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.resetHintCountdown();
    game.gameContext.haptics.tap();
    final local = event.localPosition;
    _tryAdvance(Offset(local.x, local.y));
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final local = event.localEndPosition;
    _tryAdvance(Offset(local.x, local.y));
  }

  /// Moves the frontier forward when the finger is inside the corridor
  /// near the next few samples. Leaving the corridor just pauses —
  /// progress never resets and there is no penalty of any kind.
  void _tryAdvance(Offset touch) {
    if (allDone || _finishing) return;
    final points = _current;
    final frontier = _fillPos.floor();
    final lookAhead = math.max(3, (points.length * 0.08).round());
    var best = -1;
    final end = math.min(frontier + lookAhead, points.length - 1);
    for (var i = frontier; i <= end; i++) {
      if ((points[i] - touch).distance <= corridorRadius) best = i;
    }
    if (best > frontier || (best == frontier && _fillPos == 0)) {
      _setFill(math.max(_fillPos, best.toDouble()));
      onProgress?.call();
    }
  }

  void _setFill(double value) {
    if (allDone) return;
    final points = _current;
    final maxIndex = (points.length - 1).toDouble();
    _fillPos = value.clamp(0.0, maxIndex);

    final fraction = maxIndex <= 0 ? 1.0 : _fillPos / maxIndex;
    while (fraction >= _nextMilestone && _nextMilestone < 0.85) {
      _nextMilestone += 0.25;
      game.gameContext.haptics.tap();
    }

    if (!_finishing && fraction >= 0.85) {
      // Generous completion: glide the remaining stroke closed.
      _finishing = true;
      _assistTarget = maxIndex;
      _assistRate = math.max(20.0, (maxIndex - _fillPos) / 0.35);
    }
    if (_finishing && _fillPos >= maxIndex) {
      _completeStroke();
    }
  }

  void _completeStroke() {
    final points = _current;
    final endPoint = points.last;
    add(SparkleBurst(
      at: Vector2(endPoint.dx, endPoint.dy),
      color: item.color ?? Palette.softGreen,
      reducedMotion: reducedMotion,
      count: 8,
    ));

    _strokeIndex += 1;
    _fillPos = 0;
    _assistTarget = null;
    _finishing = false;
    _nextMilestone = 0.25;

    if (allDone) {
      _popAutoDots();
      _glowAll = true;
      onItemComplete?.call();
    } else {
      onStrokeComplete?.call();
    }
  }

  void _popAutoDots() {
    final span = math.max(1.0, size.x - _inset * 2);
    for (final dot in tracePath.autoDots) {
      final circle = CircleComponent(
        radius: _fillWidth * 0.62,
        position: Vector2(_inset + dot.dx * span, _inset + dot.dy * span),
        anchor: Anchor.center,
        paint: Paint()..color = item.color ?? Palette.softGreen,
        priority: 6,
      );
      add(circle);
      game.playEffect(SoundEffect.pop);
      if (!reducedMotion) {
        circle.scale = Vector2.zero();
        circle.add(GentleEffects.popIn());
      }
    }
  }

  // ------------------------------------------------------------- helpers

  /// Hint: make the start/frontier dot pulse noticeably for a moment.
  void pulseStartDot() {
    _pulseUntil = _time + 2.6;
  }

  /// A little glowing dot travels the remaining path once.
  void runGuideDot() {
    if (allDone) return;
    final points = _current;
    final remaining = points.sublist(_fillPos.floor());
    if (remaining.length < 2) return;
    add(_RunnerDot(points: remaining, color: item.color ?? Palette.starGold));
  }

  /// Auto-assist: slowly fill the next [portion] of the current stroke so
  /// the child sees the direction (repeated assists finish the stroke).
  void assistNextPortion(double portion) {
    if (allDone || _finishing) return;
    final maxIndex = (_current.length - 1).toDouble();
    final target = math.min(maxIndex, _fillPos + portion * maxIndex);
    if (target <= _fillPos) return;
    _assistTarget = target;
    _assistRate = (target - _fillPos) / 1.4;
    game.playEffect(SoundEffect.slide);
  }

  /// Success sparkles scattered along the whole traced form.
  void celebrate() {
    final all = <Offset>[for (final s in _strokes) ...s];
    if (all.isEmpty) return;
    const bursts = 5;
    for (var i = 0; i < bursts; i++) {
      final point = all[(all.length - 1) * i ~/ (bursts - 1)];
      add(TimerComponent(
        period: 0.12 * i + 0.05,
        removeOnFinish: true,
        onTick: () => add(SparkleBurst(
          at: Vector2(point.dx, point.dy),
          color: i.isEven ? Palette.starGold : (item.color ?? Palette.softGreen),
          reducedMotion: reducedMotion,
          count: 8,
        )),
      ));
    }
  }

  // --------------------------------------------------------------- tick

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final target = _assistTarget;
    if (target != null && !allDone && _fillPos < target) {
      _setFill(math.min(target, _fillPos + _assistRate * dt));
      if (_assistTarget != null && _fillPos >= _assistTarget! && !_finishing) {
        _assistTarget = null;
      }
    }
  }

  // ------------------------------------------------------------- render

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderCard(canvas);
    for (var i = 0; i < _strokes.length; i++) {
      if (i > _strokeIndex) _renderGuide(canvas, _strokes[i], future: true);
    }
    if (!allDone) _renderGuide(canvas, _current);
    for (var i = 0; i < math.min(_strokeIndex, _strokes.length); i++) {
      _renderFill(canvas, _strokes[i], _strokes[i].length - 1.0);
    }
    if (!allDone && _fillPos > 0) {
      _renderFill(canvas, _current, _fillPos);
    }
    if (!allDone) {
      _renderChevron(canvas);
      _renderStartDot(canvas);
    }
  }

  void _renderCard(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.09),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = highContrast
            ? Palette.outlineStrong
            : Palette.outline.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highContrast ? 4 : 3,
    );
  }

  Path _polylinePath(List<Offset> points, double upTo) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    final whole = upTo.floor().clamp(0, points.length - 1);
    for (var i = 1; i <= whole; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    final t = upTo - whole;
    if (t > 0 && whole < points.length - 1) {
      final partial = Offset.lerp(points[whole], points[whole + 1], t)!;
      path.lineTo(partial.dx, partial.dy);
    }
    return path;
  }

  void _renderGuide(Canvas canvas, List<Offset> points, {bool future = false}) {
    final path = _polylinePath(points, points.length - 1.0);
    final bandAlpha = future ? 0.08 : (highContrast ? 0.26 : 0.15);
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.outline.withValues(alpha: bandAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _guideWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Dotted centre line.
    final dotColor = highContrast
        ? Palette.outlineStrong.withValues(alpha: future ? 0.35 : 0.85)
        : Palette.outline.withValues(alpha: future ? 0.25 : 0.55);
    final dotPaint = Paint()..color = dotColor;
    var travelled = 0.0;
    var nextDot = 0.0;
    for (var i = 1; i < points.length; i++) {
      final segment = (points[i] - points[i - 1]).distance;
      while (nextDot <= travelled + segment && segment > 0) {
        final t = (nextDot - travelled) / segment;
        final p = Offset.lerp(points[i - 1], points[i], t)!;
        canvas.drawCircle(p, 4.4, dotPaint);
        nextDot += 18;
      }
      travelled += segment;
    }
  }

  void _renderFill(Canvas canvas, List<Offset> points, double upTo) {
    if (upTo <= 0) return;
    final path = _polylinePath(points, upTo);
    final color = item.color ?? Palette.softGreen;
    if (_glowAll) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Palette.starGold.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _fillWidth + 14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _fillWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Offset _pointAt(List<Offset> points, double index) {
    final whole = index.floor().clamp(0, points.length - 1);
    final t = index - whole;
    if (t <= 0 || whole >= points.length - 1) return points[whole];
    return Offset.lerp(points[whole], points[whole + 1], t)!;
  }

  void _renderChevron(Canvas canvas) {
    final points = _current;
    final ahead = (_fillPos + math.max(4.0, points.length * 0.07))
        .clamp(0.0, points.length - 1.0);
    if (ahead - _fillPos < 1) return;
    final at = _pointAt(points, ahead);
    final before = _pointAt(points, math.max(0, ahead - 2));
    final direction = at - before;
    if (direction.distance < 0.01) return;
    final angle = math.atan2(direction.dy, direction.dx);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    final chevron = Path()
      ..moveTo(-7, -7)
      ..lineTo(3, 0)
      ..lineTo(-7, 7);
    canvas.drawPath(
      chevron,
      Paint()
        ..color = Palette.outline.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  void _renderStartDot(Canvas canvas) {
    final at = _pointAt(_current, _fillPos);
    final boosted = _time < _pulseUntil;
    final wave = reducedMotion ? 0.0 : math.sin(_time * 3.4) * 2.6;
    final radius = (15.0 + wave) * (boosted ? 1.35 : 1.0);
    canvas.drawCircle(
      at,
      radius + 7,
      Paint()
        ..color = Palette.starGold.withValues(alpha: boosted ? 0.4 : 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(at, radius, Paint()..color = Palette.starGold);
    canvas.drawCircle(
      at,
      radius * 0.42,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9),
    );
  }
}

// ===================================================================
// Small support components
// ===================================================================

/// A soft glowing dot that travels the remaining path once (highlight).
class _RunnerDot extends PositionComponent {
  _RunnerDot({
    required this.points,
    required this.color,
  }) : super(priority: 8);

  final List<Offset> points;
  final Color color;

  static const double duration = 1.7;

  double _t = 0;
  Offset _at = Offset.zero;

  @override
  Future<void> onLoad() async {
    _at = points.first;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final f = (_t / duration).clamp(0.0, 1.0);
    final index = f * (points.length - 1);
    final whole = index.floor().clamp(0, points.length - 1);
    final frac = index - whole;
    _at = whole >= points.length - 1
        ? points.last
        : Offset.lerp(points[whole], points[whole + 1], frac)!;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      _at,
      16,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(_at, 9, Paint()..color = color);
    canvas.drawCircle(
      _at,
      4,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9),
    );
  }
}

/// Small corner card showing the item being traced.
class _PreviewTile extends PositionComponent {
  _PreviewTile({
    required this.item,
    required this.highContrast,
    required super.position,
    required Vector2 super.size,
  }) : super(anchor: Anchor.center, priority: 4);

  final ContentItem item;
  final bool highContrast;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.22),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = highContrast
            ? Palette.outlineStrong
            : Palette.outline.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highContrast ? 4 : 3,
    );
    canvas.save();
    final inset = size.x * 0.14;
    canvas.translate(inset, inset);
    ItemArt.paint(
      canvas,
      Size(size.x - inset * 2, size.y - inset * 2),
      item,
      highContrast: highContrast,
    );
    canvas.restore();
  }
}

class _SoftBackground extends PositionComponent {
  _SoftBackground({required Vector2 super.size}) : super(priority: -10);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.skyDay, Palette.cream],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.x * 0.1, size.y * 0.14),
      36,
      Paint()..color = Palette.butter.withValues(alpha: 0.8),
    );
  }
}
