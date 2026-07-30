import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
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

/// PatternComplete — "what comes next?"
///
/// A friendly caterpillar carries a row of item bubbles across the
/// upper-middle of the screen showing a repeating pattern, ending in one
/// empty dashed bubble with a soft '?'. The child taps the item that comes
/// next from big choice tiles along the bottom.
///
/// Pattern rule follows [BandConfig.patternLength] (overridable per node
/// with params['patternLength']): 2 = AB AB…, 3 = ABC ABC…, 4 = AABB AABB….
/// Choice count follows [BandConfig.patternChoices] (params
/// ['patternChoices']). Rounds per play: params['rounds'] (default 3).
/// Content resolves from the spec's content pack.
class PatternCompleteGame extends ToddlerGame {
  PatternCompleteGame(super.gameContext);

  static final math.Random _random = math.Random();

  late final List<ContentItem> _pool;
  late final int _rounds;

  int _round = 0;
  bool _roundSolved = false;

  _CaterpillarStrip? _strip;
  final List<_ChoiceTile> _tiles = [];
  _ChoiceTile? _correctTile;
  ContentItem? _answer;

  @override
  Color backgroundColor() => Palette.cream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final spec = gameContext.spec;
    var pool = spec == null || spec.contentPack.isEmpty
        ? ItemCatalog.shapes
        : spec.contentPack == 'letters'
            ? ItemCatalog.lettersFor(gameContext.languageCode)
            : ItemCatalog.pack(spec.contentPack);
    // A pattern needs up to three distinct items; fall back gracefully.
    if (pool.length < 3) pool = ItemCatalog.shapes;
    _pool = pool;
    _rounds = gameContext.param('rounds', 3);

    await add(_SoftBackground(size: size.clone()));
    await addMilo();
    say(VoiceInstruction.patternIntro);
    add(TimerComponent(
      period: 1.8,
      removeOnFinish: true,
      onTick: _startRound,
    ));
  }

  /// 2 = AB, 3 = ABC, 4 = AABB.
  int get _unitLength {
    final band = gameContext.bandConfig;
    return gameContext.param('patternLength', band.patternLength).clamp(2, 4);
  }

  int get _choiceCount {
    final band = gameContext.bandConfig;
    final wanted = gameContext.param('patternChoices', band.patternChoices);
    return wanted.clamp(2, math.max(2, _pool.length));
  }

  // ------------------------------------------------------------- rounds

  void _clearRound() {
    _strip?.removeFromParent();
    _strip = null;
    for (final tile in _tiles) {
      tile.removeFromParent();
    }
    _tiles.clear();
    _correctTile = null;
    _answer = null;
  }

  void _startRound() {
    if (isCompleted) return;
    _clearRound();
    _roundSolved = false;

    final unitLen = _unitLength;
    final distinct = unitLen == 3 ? 3 : 2;
    final options = [..._pool]..shuffle(_random);
    final picks = options.take(distinct).toList();
    final unit = switch (unitLen) {
      2 => [picks[0], picks[1]],
      3 => [picks[0], picks[1], picks[2]],
      _ => [picks[0], picks[0], picks[1], picks[1]],
    };

    // Enough visible bubbles that the rule repeats readably (4-6).
    final visible = unitLen == 2
        ? 4
        : unitLen == 3
            ? 5
            : 6;
    final sequence = [
      for (var i = 0; i < visible; i++) unit[i % unit.length],
    ];
    final answer = unit[visible % unit.length];
    _answer = answer;

    _buildStrip(sequence);
    _buildChoices(unit, answer);

    say(VoiceInstruction.patternNext);
    startHintCountdown();
  }

  void _buildStrip(List<ContentItem> sequence) {
    final slots = sequence.length + 1; // pattern bubbles + the gap
    final fitted = size.x * 0.84 / (slots + 1.3);
    final bubbleDiameter = math
        .min(fitted, 96.0 * gameContext.bandConfig.itemScale)
        .clamp(50.0, 120.0);
    final strip = _CaterpillarStrip(
      sequence: sequence,
      bubbleDiameter: bubbleDiameter,
      highContrast: highContrast,
      reducedMotion: reducedMotion,
      position: Vector2(size.x / 2, size.y * 0.32),
    );
    _strip = strip;
    add(strip);
  }

  void _buildChoices(List<ContentItem> unit, ContentItem answer) {
    // Distractors: the other pattern items first (the real decision),
    // then fresh items from the pack.
    final seen = <String>{answer.id};
    final distractors = <ContentItem>[];
    for (final item in unit) {
      if (seen.add(item.id)) distractors.add(item);
    }
    final rest = [..._pool]..shuffle(_random);
    for (final item in rest) {
      if (seen.add(item.id)) distractors.add(item);
    }
    final chosen = [answer, ...distractors.take(_choiceCount - 1)]
      ..shuffle(_random);

    final tileSize = (math.min(size.x, size.y) * 0.28).clamp(110.0, 190.0) *
        gameContext.bandConfig.itemScale;
    final centerY = size.y * 0.74;
    final spacing = math.min(
        tileSize * 1.35, (size.x - 240) / math.max(1, chosen.length));
    final startX = size.x / 2 - spacing * (chosen.length - 1) / 2;

    for (var i = 0; i < chosen.length; i++) {
      final item = chosen[i];
      final tile = _ChoiceTile(
        item: item,
        highContrast: highContrast,
        position: Vector2(startX + spacing * i, centerY),
        size: Vector2.all(tileSize),
        onPressed: (t) => _onTileTapped(t as _ChoiceTile),
      );
      if (item.id == answer.id && _correctTile == null) _correctTile = tile;
      _tiles.add(tile);
      add(tile);
      tile.scale = Vector2.zero();
      tile.add(GentleEffects.popIn());
    }
  }

  // -------------------------------------------------------- interaction

  void _onTileTapped(_ChoiceTile tile) {
    if (isCompleted || _roundSolved) return;
    if (tile.item.id == _answer?.id) {
      _onCorrect(tile);
    } else {
      tile.add(GentleEffects.wobble());
      handleWrongAttempt();
    }
  }

  void _onCorrect(_ChoiceTile tile) {
    if (_roundSolved) return;
    _roundSolved = true;
    registerCorrectAction();
    stopHintCountdown();
    for (final t in _tiles) {
      t.enabled = false;
      t.hideHighlight();
    }

    final strip = _strip;
    final answer = _answer;
    if (strip != null && answer != null) {
      final gap = strip.gapBubble;
      gap?.hideGlow();
      final sparkleAt =
          gap?.absoluteCenter.clone() ?? tile.position.clone();
      strip.fillGap(answer);
      strip.wiggle();
      add(SparkleBurst(
        at: sparkleAt,
        color: answer.color ?? Palette.starGold,
        reducedMotion: reducedMotion,
      ));
    }
    playEffect(SoundEffect.chimeSuccess);
    tile.add(GentleEffects.happyHop());
    if (_random.nextBool()) milo?.laugh();

    _round += 1;
    if (_round >= _rounds) {
      add(TimerComponent(
        period: 1.2,
        removeOnFinish: true,
        onTick: () => completeGame(voice: VoiceInstruction.greatJob),
      ));
    } else {
      add(TimerComponent(
        period: 1.5,
        removeOnFinish: true,
        onTick: _startRound,
      ));
    }
  }

  // --------------------------------------------------------------- hints

  @override
  void showHint() {
    if (_roundSolved) return;
    final correct = _correctTile;
    if (correct == null) return;
    correct.pulse();
    _strip?.gapBubble?.showGlow();
    milo?.pointTowards(correct.position.x >= size.x / 2 ? 1 : -1);
  }

  @override
  void repeatInstruction() => say(VoiceInstruction.patternNext);

  @override
  void highlightTarget() {
    if (_roundSolved) return;
    _correctTile?.showHighlight();
    _strip?.gapBubble?.showGlow();
    repeatInstruction();
  }

  @override
  void autoAssist() {
    final correct = _correctTile;
    if (correct == null || _roundSolved) return;
    correct.showHighlight();
    _onCorrect(correct);
  }
}

/// The whole caterpillar: head + pattern bubbles + the empty gap bubble.
/// Kept in one container so the strip can do a happy wiggle together.
class _CaterpillarStrip extends PositionComponent {
  _CaterpillarStrip({
    required this.sequence,
    required this.bubbleDiameter,
    required this.highContrast,
    required this.reducedMotion,
    required super.position,
  }) : super(anchor: Anchor.center);

  final List<ContentItem> sequence;
  final double bubbleDiameter;
  final bool highContrast;
  final bool reducedMotion;

  _PatternBubble? _gapBubble;
  _PatternBubble? get gapBubble => _gapBubble;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final d = bubbleDiameter;
    final headDiameter = d * 1.15;
    final step = d * 1.04;
    final slots = sequence.length + 1;
    size = Vector2(headDiameter + step * slots + d * 0.1, headDiameter + 16);
    final centerY = size.y / 2;

    final head = _CaterpillarHead(
      diameter: headDiameter,
      highContrast: highContrast,
      position: Vector2(headDiameter / 2, centerY),
    );
    await add(head);

    final firstX = headDiameter + d / 2;
    for (var i = 0; i < slots; i++) {
      final isGap = i == sequence.length;
      final bubble = _PatternBubble(
        isGap ? null : sequence[i],
        diameter: d,
        highContrast: highContrast,
        reducedMotion: reducedMotion,
        position: Vector2(
          firstX + step * i,
          centerY + (i.isEven ? -d * 0.05 : d * 0.05),
        ),
      );
      if (isGap) _gapBubble = bubble;
      await add(bubble);
      if (!reducedMotion) {
        bubble.scale = Vector2.zero();
        bubble.add(ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: 0.3,
            startDelay: 0.06 * i,
            curve: Curves.easeOutBack,
          ),
        ));
      }
    }
  }

  /// The chosen item pops into the empty bubble.
  void fillGap(ContentItem item) => _gapBubble?.fill(item);

  /// Happy little wiggle after a correct answer.
  void wiggle() {
    if (reducedMotion) return;
    add(GentleEffects.wobble(angle: 0.04, repeats: 2));
  }
}

/// One caterpillar segment: a soft round bubble. With an item it shows the
/// item's art; empty it shows a dashed outline and a gentle '?'.
class _PatternBubble extends PositionComponent {
  _PatternBubble(
    this._item, {
    required double diameter,
    required this.highContrast,
    required this.reducedMotion,
    required super.position,
  }) : super(size: Vector2.all(diameter), anchor: Anchor.center);

  final bool highContrast;
  final bool reducedMotion;

  ContentItem? _item;
  GlowHighlight? _glow;
  TextPainter? _questionMark;

  /// The answer arriving: fill and pop in.
  void fill(ContentItem item) {
    _item = item;
    if (!reducedMotion) {
      scale = Vector2.all(0.3);
      add(GentleEffects.popIn());
    }
  }

  void showGlow() {
    if (_glow != null && _glow!.isMounted) return;
    _glow = GlowHighlight(radius: size.x / 2 + 14);
    add(_glow!..position = Vector2(size.x / 2, size.y / 2));
  }

  void hideGlow() {
    _glow?.dismiss();
    _glow = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2 - 3;
    final item = _item;

    // Little feet so the strip reads as a caterpillar.
    final feet = Paint()
      ..color = (highContrast ? Palette.outlineStrong : Palette.outline)
          .withValues(alpha: 0.55);
    canvas.drawCircle(Offset(size.x * 0.34, size.y - 3), size.x * 0.045, feet);
    canvas.drawCircle(Offset(size.x * 0.66, size.y - 3), size.x * 0.045, feet);

    if (item == null) {
      // Empty bubble: soft fill, dashed outline, gentle '?'.
      canvas.drawCircle(
          center, radius, Paint()..color = Palette.butter.withValues(alpha: 0.4));
      final dash = Paint()
        ..color = highContrast
            ? Palette.outlineStrong
            : Palette.outline.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highContrast ? 4 : 3
        ..strokeCap = StrokeCap.round;
      const dashCount = 12;
      const sweep = 2 * math.pi / dashCount;
      final arcRect = Rect.fromCircle(center: center, radius: radius);
      for (var i = 0; i < dashCount; i++) {
        canvas.drawArc(arcRect, sweep * i, sweep * 0.55, false, dash);
      }
      final mark = _questionMark ??= TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            fontSize: size.x * 0.42,
            fontWeight: FontWeight.w600,
            color: Palette.textSoft,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      mark.paint(
        canvas,
        Offset(center.dx - mark.width / 2, center.dy - mark.height / 2),
      );
      return;
    }

    canvas.drawCircle(center, radius,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = highContrast
            ? Palette.outlineStrong
            : Palette.outline.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highContrast ? 4 : 3,
    );
    canvas.save();
    final inset = size.x * 0.15;
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

/// The caterpillar's friendly face at the front of the strip.
class _CaterpillarHead extends PositionComponent {
  _CaterpillarHead({
    required double diameter,
    required this.highContrast,
    required super.position,
  }) : super(size: Vector2.all(diameter), anchor: Anchor.center);

  final bool highContrast;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2 - 3;
    final line = Paint()
      ..color = highContrast
          ? Palette.outlineStrong
          : Palette.outlineStrong.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 4 : 3
      ..strokeCap = StrokeCap.round;

    // Antennae with soft tips.
    final tipPaint = Paint()..color = Palette.blush;
    canvas.drawLine(Offset(center.dx - radius * 0.35, center.dy - radius * 0.8),
        Offset(center.dx - radius * 0.55, center.dy - radius * 1.25), line);
    canvas.drawLine(Offset(center.dx + radius * 0.35, center.dy - radius * 0.8),
        Offset(center.dx + radius * 0.55, center.dy - radius * 1.25), line);
    canvas.drawCircle(
        Offset(center.dx - radius * 0.55, center.dy - radius * 1.25),
        radius * 0.14,
        tipPaint);
    canvas.drawCircle(
        Offset(center.dx + radius * 0.55, center.dy - radius * 1.25),
        radius * 0.14,
        tipPaint);

    // Head.
    canvas.drawCircle(center, radius, Paint()..color = Palette.softGreen);
    canvas.drawCircle(center, radius, line);

    // Face looks toward the bubbles (to the right).
    final eye = Paint()..color = Palette.outlineStrong;
    canvas.drawCircle(
        Offset(center.dx + radius * 0.18, center.dy - radius * 0.18),
        radius * 0.1,
        eye);
    canvas.drawCircle(
        Offset(center.dx + radius * 0.62, center.dy - radius * 0.18),
        radius * 0.1,
        eye);
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(center.dx + radius * 0.4, center.dy + radius * 0.22),
          radius: radius * 0.28),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      line,
    );
    canvas.drawCircle(
        Offset(center.dx - radius * 0.3, center.dy + radius * 0.25),
        radius * 0.16,
        Paint()..color = Palette.miloCheek.withValues(alpha: 0.6));
  }
}

/// A large tappable answer tile (rounded card + ItemArt drawing), following
/// the reference ItemTile pattern.
class _ChoiceTile extends TapTarget {
  _ChoiceTile({
    required this.item,
    this.highContrast = false,
    required super.position,
    required super.size,
    super.onPressed,
  }) : super(targetId: item.id);

  final ContentItem item;
  final bool highContrast;

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.22),
    );
    canvas.drawRRect(rect,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92));
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
    final inset = size.x * 0.1;
    canvas.translate(inset, inset);
    ItemArt.paint(
      canvas,
      Size(size.x - inset * 2, size.y - inset * 2),
      item,
      highContrast: highContrast,
    );
    canvas.restore();
    super.render(canvas);
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
          colors: [Palette.meadow, Palette.cream],
        ).createShader(rect),
    );
    canvas.drawCircle(Offset(size.x * 0.9, size.y * 0.12), 40,
        Paint()..color = Palette.butter.withValues(alpha: 0.8));
    canvas.drawCircle(Offset(size.x * 0.08, size.y * 0.16), 26,
        Paint()..color = Palette.mint.withValues(alpha: 0.55));
  }
}
