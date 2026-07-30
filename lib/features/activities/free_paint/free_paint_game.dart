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
import '../../../shared/components/tap_target.dart';
import '../../../shared/game/toddler_game.dart';
import '../../../shared/items/item_art.dart';

/// Creative engine — FreePaint.
///
/// An open-ended art table: finger-paint with big soft strokes, or (in
/// stamps mode, params {'stamps': 1}) tap to place picture stamps from the
/// spec's content pack. There is no wrong way to paint; the big star
/// finishes the picture whenever the child is happy with it.
class FreePaintGame extends ToddlerGame {
  FreePaintGame(super.gameContext);

  static const List<Color> _brushColors = [
    Palette.softRed,
    Palette.softOrange,
    Palette.softYellow,
    Palette.softGreen,
    Palette.softBlue,
    Palette.softPurple,
  ];

  late final bool _stampsMode;
  late final List<ContentItem> _stampPool;

  late _PaintCanvas _canvas;
  late TapTarget _doneStar;
  final List<_ColorDot> _dots = [];
  int _stampIndex = 0;
  int _marks = 0;
  bool _assisted = false;

  @override
  Color backgroundColor() => Palette.cream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final spec = gameContext.spec;
    _stampsMode = gameContext.param('stamps', 0) == 1;
    final packName = spec?.contentPack ?? '';
    final pack = packName == 'letters'
        ? ItemCatalog.lettersFor(gameContext.languageCode)
        : ItemCatalog.pack(packName);
    _stampPool = pack.isEmpty ? ItemCatalog.animals : pack;

    await addMilo(height: 120);

    // Paper.
    _canvas = _PaintCanvas(
      position: Vector2(size.x / 2, size.y / 2 - 10),
      size: Vector2(size.x * 0.62, size.y * 0.74),
      brushColor: _brushColors[4],
      onMark: _onMark,
      stampBuilder: _stampsMode ? _currentStamp : null,
    );
    await add(_canvas);

    // Color palette dots along the side opposite Milo.
    final paletteX =
        gameContext.leftHanded ? size.x * 0.085 : size.x * 0.915;
    for (var i = 0; i < _brushColors.length; i++) {
      final dot = _ColorDot(
        color: _brushColors[i],
        position: Vector2(
          paletteX,
          size.y * 0.16 + i * (size.y * 0.68 / (_brushColors.length - 1)),
        ),
        onPicked: (color) {
          _canvas.brushColor = color;
          for (final d in _dots) {
            d.selected = d.color == color;
          }
          playEffect(SoundEffect.pop);
        },
      )..selected = i == 4;
      _dots.add(dot);
      await add(dot);
    }

    // Done star (big, above Milo's corner).
    _doneStar = TapTarget(
      targetId: 'done',
      position: Vector2(
        gameContext.leftHanded ? size.x - 90 : 90,
        size.y * 0.2,
      ),
      size: Vector2.all(104),
      paintItem: (canvas, s) => ItemArt.paint(
        canvas,
        Size(s.x, s.y),
        const ContentItem(
            id: 'done', artId: 'shape_star', color: Palette.starGold),
        highContrast: highContrast,
      ),
      onPressed: (_) => _finish(),
    );
    await add(_doneStar);

    say(VoiceInstruction.paintIntro);
    startHintCountdown();
  }

  ContentItem _currentStamp() {
    final stamp = _stampPool[_stampIndex % _stampPool.length];
    _stampIndex += 1;
    return stamp;
  }

  void _onMark() {
    _marks += 1;
    registerCorrectAction();
    if (_marks == 1 || _marks % 6 == 0) {
      gameContext.haptics.tap();
    }
    if (_marks == 8) milo?.laugh();
  }

  void _finish() {
    if (_marks < 1) {
      // Nothing painted yet: encourage instead of finishing.
      say(VoiceInstruction.paintIntro);
      _canvas.add(GentleEffects.attentionPulse(by: 1.03, repeats: 1));
      return;
    }
    add(SparkleBurst(
      at: _doneStar.position.clone(),
      reducedMotion: reducedMotion,
    ));
    completeGame(voice: VoiceInstruction.paintDone);
  }

  @override
  void showHint() {
    milo?.pointTowards(
        _canvas.position.x >= size.x / 2 ? 1 : -1);
    say(VoiceInstruction.paintIntro);
  }

  @override
  void repeatInstruction() => say(VoiceInstruction.paintIntro);

  @override
  void highlightTarget() {
    _canvas.add(GentleEffects.attentionPulse(by: 1.03, repeats: 2));
  }

  /// Paints a little smiley to show how it works; a second assist (or the
  /// star) finishes the picture so nobody is ever stuck here.
  @override
  void autoAssist() {
    if (_assisted && _marks > 0) {
      _finish();
      return;
    }
    _assisted = true;
    _canvas.paintDemoSmiley();
    _onMark();
    _doneStar.pulse();
  }
}

class _PaintCanvas extends PositionComponent with DragCallbacks, TapCallbacks {
  _PaintCanvas({
    required super.position,
    required Vector2 super.size,
    required this.brushColor,
    required this.onMark,
    this.stampBuilder,
  }) : super(anchor: Anchor.center);

  Color brushColor;
  final VoidCallback onMark;

  /// Non-null in stamps mode: provides the next stamp to place on tap.
  final ContentItem Function()? stampBuilder;

  final List<_Stroke> _strokes = [];
  final List<(ContentItem, Vector2)> _stamps = [];
  _Stroke? _active;

  static const double _brushWidth = 22;
  static const int _maxStrokes = 220;

  bool _inside(Vector2 p) =>
      p.x >= 0 && p.y >= 0 && p.x <= size.x && p.y <= size.y;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final builder = stampBuilder;
    if (builder == null) return;
    if (!_inside(event.localPosition)) return;
    _stamps.add((builder(), event.localPosition.clone()));
    onMark();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _active = _Stroke(brushColor, [event.localPosition.clone()]);
    if (_strokes.length < _maxStrokes) _strokes.add(_active!);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final active = _active;
    if (active == null) return;
    final next = active.points.last + event.localDelta;
    if (_inside(next)) active.points.add(next);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if ((_active?.points.length ?? 0) > 2) onMark();
    _active = null;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _active = null;
  }

  void paintDemoSmiley() {
    final c = Vector2(size.x / 2, size.y / 2);
    final r = size.y * 0.18;
    // Face outline.
    _strokes.add(_Stroke(Palette.softYellow, [
      for (var a = 0.0; a <= 2 * math.pi + 0.2; a += 0.35)
        Vector2(c.x + r * 1.1 * math.cos(a), c.y + r * 1.1 * math.sin(a)),
    ]));
    // Eyes (dots).
    _strokes.add(_Stroke(Palette.softBlue,
        [c + Vector2(-r * 0.45, -r * 0.3)]));
    _strokes.add(_Stroke(Palette.softBlue,
        [c + Vector2(r * 0.45, -r * 0.3)]));
    // Smile arc.
    _strokes.add(_Stroke(Palette.softRed, [
      for (var a = 0.5; a <= 2.65; a += 0.3)
        Vector2(c.x + r * 0.6 * math.cos(a), c.y + r * 0.55 * math.sin(a)),
    ]));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Paper.
    final paper = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(26),
    );
    canvas.drawRRect(paper, Paint()..color = const Color(0xFFFFFEFA));
    canvas.drawRRect(
      paper,
      Paint()
        ..color = Palette.outline.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.save();
    canvas.clipRRect(paper);
    for (final (item, at) in _stamps) {
      canvas.save();
      canvas.translate(at.x - 45, at.y - 45);
      ItemArt.paint(canvas, const Size(90, 90), item);
      canvas.restore();
    }
    for (final stroke in _strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _brushWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (stroke.points.length == 1 ||
          (stroke.points.length == 2 &&
              stroke.points[0].distanceTo(stroke.points[1]) < 3)) {
        canvas.drawCircle(
          Offset(stroke.points.first.x, stroke.points.first.y),
          _brushWidth / 2,
          Paint()..color = stroke.color,
        );
        continue;
      }
      final path = Path()
        ..moveTo(stroke.points.first.x, stroke.points.first.y);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }
}

class _Stroke {
  _Stroke(this.color, this.points);

  final Color color;
  final List<Vector2> points;
}

class _ColorDot extends TapTarget {
  _ColorDot({
    required this.color,
    required super.position,
    required void Function(Color color) onPicked,
  }) : super(
          targetId: 'dot',
          size: Vector2.all(74),
        ) {
    onPressed = (_) => onPicked(color);
  }

  final Color color;
  bool selected = false;

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 - 4,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 - 4,
      Paint()
        ..color = selected
            ? Palette.outlineStrong
            : Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 5 : 3,
    );
    super.render(canvas);
  }
}
