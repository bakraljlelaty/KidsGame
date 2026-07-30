import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../../content/items/content_item.dart';
import '../../../content/items/item_catalog.dart';
import '../../../core/audio/sound_effects.dart';
import '../../../core/audio/voice_catalog.dart';
import '../../../core/theme/palette.dart';
import '../../../shared/components/draggable_item.dart';
import '../../../shared/components/drop_zone.dart';
import '../../../shared/components/gentle_effects.dart';
import '../../../shared/game/toddler_game.dart';
import '../../../shared/items/item_art.dart';

/// CountAndGive — "give me N" quantities.
///
/// Milo sits beside a big open basket. A tray of identical items (one item
/// type per round, N + 2 of them) is scattered across the play area. Milo
/// asks for N; every item dragged into the basket dings, speaks the running
/// count and shows a big friendly numeral. When the basket holds N it closes
/// with a happy waggle and the spare items drift away. There is no wrong
/// answer in this engine: extra or stray drops simply float home.
///
/// Rounds per play: params['rounds'] (default 2). N is random in
/// 1..countingMax (band, overridable via params['countMax']).
class CountAndGiveGame extends ToddlerGame {
  CountAndGiveGame(super.gameContext);

  static final math.Random _random = math.Random();

  static const List<VoiceInstruction> _countVoices = [
    VoiceInstruction.countOne,
    VoiceInstruction.countTwo,
    VoiceInstruction.countThree,
    VoiceInstruction.countFour,
    VoiceInstruction.countFive,
    VoiceInstruction.countSix,
    VoiceInstruction.countSeven,
    VoiceInstruction.countEight,
    VoiceInstruction.countNine,
    VoiceInstruction.countTen,
  ];

  late final List<ContentItem> _pool;
  late final int _rounds;
  late final _BasketZone _basket;

  final List<_GiveItem> _items = [];
  _CountNumeral? _numeral;

  int _round = 0;
  int _target = 1;
  int _lastTarget = 0;

  /// Items that have finished snapping into the basket.
  int _given = 0;

  /// Items accepted by the basket (including ones still gliding in).
  int _pending = 0;

  /// Consecutive automatic hints without progress; every third one gently
  /// floats an item in so no child ever gets stuck.
  int _hintStreak = 0;

  bool _roundResolved = true;

  @override
  Color backgroundColor() => Palette.cream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spec = gameContext.spec;
    final specPack = spec == null
        ? const <ContentItem>[]
        : spec.contentPack == 'letters'
            ? ItemCatalog.lettersFor(gameContext.languageCode)
            : ItemCatalog.pack(spec.contentPack);
    _pool = specPack.isEmpty ? ItemCatalog.shapes : specPack;
    _rounds = gameContext.param('rounds', 2);

    await add(_SoftBackground(size: size.clone()));

    final basketWidth = (math.min(size.x, size.y) * 0.48).clamp(210.0, 320.0);
    final basketSize = Vector2(basketWidth, basketWidth * 0.62);
    final miloClearance = 195.0 + basketSize.x / 2;
    _basket = _BasketZone(
      position: Vector2(
        gameContext.leftHanded ? size.x - miloClearance : miloClearance,
        size.y - basketSize.y / 2 - 20,
      ),
      size: basketSize,
      highContrast: highContrast,
    );
    // resolveDrop calls acceptTest at most once per resolved drop, so it is
    // safe to reserve the slot here: this is what keeps the basket from ever
    // taking more than N items even while several are gliding in.
    _basket.acceptTest = (item) {
      if (isCompleted || _roundResolved || _pending >= _target) return false;
      _noteIncoming();
      return true;
    };
    _basket.onAccepted = (item) => _onItemArrived(item as _GiveItem);
    await add(_basket);

    await addMilo();
    say(VoiceInstruction.countIntro);
    add(TimerComponent(period: 1.6, removeOnFinish: true, onTick: _startRound));
  }

  // ------------------------------------------------------------- rounds

  void _startRound() {
    if (isCompleted) return;
    _clearRound();
    _given = 0;
    _pending = 0;
    _hintStreak = 0;

    final band = gameContext.bandConfig;
    final maxN =
        gameContext.param('countMax', band.countingMax).clamp(1, _countVoices.length);
    var target = 1 + _random.nextInt(maxN);
    if (maxN > 1 && target == _lastTarget) {
      target = 1 + _random.nextInt(maxN);
    }
    _target = target;
    _lastTarget = target;

    _basket
      ..closed = false
      ..enabled = true
      ..hideHighlight();
    _roundResolved = false;

    final type = _pool[_random.nextInt(_pool.length)];
    _spawnItems(_target + 2, type);
    _sayPrompt();
    startHintCountdown();
  }

  void _clearRound() {
    for (final item in List<_GiveItem>.of(_items)) {
      item.removeFromParent();
    }
    _items.clear();
    _numeral?.removeFromParent();
    _numeral = null;
  }

  void _spawnItems(int count, ContentItem type) {
    final band = gameContext.bandConfig;
    final desired =
        (math.min(size.x, size.y) * 0.2).clamp(92.0, 150.0) * band.itemScale;

    // Scatter region: the open area above the basket and Milo.
    final left = size.x * 0.06;
    final right = size.x * 0.94;
    final top = size.y * 0.13;
    final bottom = math.min(
      size.y * 0.60,
      _basket.position.y - _basket.size.y / 2 - desired * 0.35,
    );
    final regionW = right - left;
    final regionH = math.max(desired, bottom - top);

    final rows = math.max(1, math.sqrt(count * regionH / regionW).round());
    final cols = (count / rows).ceil();
    final cellW = regionW / cols;
    final cellH = regionH / rows;
    final itemSize = math.min(desired, math.min(cellW, cellH) * 0.9);

    final cells = <Vector2>[
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++)
          Vector2(left + cellW * (c + 0.5), top + cellH * (r + 0.5)),
    ]..shuffle(_random);

    for (var i = 0; i < count; i++) {
      final cell = cells[i];
      final jitterX = math.min(26.0, math.max(0.0, (cellW - itemSize) / 2));
      final jitterY = math.min(26.0, math.max(0.0, (cellH - itemSize) / 2));
      final item = _GiveItem(
        item: type,
        index: i,
        highContrast: highContrast,
        position: Vector2(
          cell.x + (_random.nextDouble() * 2 - 1) * jitterX,
          cell.y + (_random.nextDouble() * 2 - 1) * jitterY,
        ),
        size: Vector2.all(itemSize),
      );
      _items.add(item);
      add(item);
      if (!reducedMotion) {
        item.scale = Vector2.zero();
        item.add(GentleEffects.popIn());
      }
    }
  }

  void _sayPrompt() {
    say(VoiceInstruction.giveMe);
    add(TimerComponent(
      period: 1.2,
      removeOnFinish: true,
      onTick: () {
        if (!isCompleted) say(_countVoices[_target - 1]);
      },
    ));
  }

  // -------------------------------------------------------- interaction

  void _noteIncoming() {
    _pending += 1;
    if (_pending >= _target) {
      // Basket is full (counting the ones gliding in): later drops find no
      // willing zone and simply drift home — never a wrong attempt.
      _basket.enabled = false;
    }
  }

  void _onItemArrived(_GiveItem item) {
    if (isCompleted) return;
    _given += 1;
    _hintStreak = 0;
    registerCorrectAction();
    _basket.hideHighlight();
    item.settleIntoBasket(
      index: _given - 1,
      columns: math.min(_target, 5),
      basketSize: _basket.size,
      reducedMotion: reducedMotion,
    );
    _showNumeral(_given);
    say(_countVoices[math.min(_given, _countVoices.length) - 1]);
    if (_given >= _target) {
      _resolveRound();
    } else if (_random.nextInt(3) == 0) {
      milo?.laugh();
    }
  }

  void _showNumeral(int value) {
    _numeral?.removeFromParent();
    final numeral = _CountNumeral(
      text: '$value',
      position: Vector2(
        _basket.position.x,
        math.max(70.0, _basket.position.y - _basket.size.y / 2 - 78),
      ),
      reducedMotion: reducedMotion,
    );
    _numeral = numeral;
    add(numeral);
  }

  void _resolveRound() {
    _roundResolved = true;
    stopHintCountdown();
    _basket
      ..enabled = false
      ..closed = true
      ..hideHighlight()
      ..celebrateWobble(reducedMotion: reducedMotion);
    playEffect(SoundEffect.chimeSuccess);
    add(SparkleBurst(
      at: Vector2(_basket.position.x, _basket.position.y - _basket.size.y * 0.35),
      color: Palette.starGold,
      reducedMotion: reducedMotion,
    ));
    milo?.celebrate();

    // Spare tray items are no longer needed: fade them gently away.
    for (final item in _items) {
      if (item.draggable) item.fadeAway(reducedMotion: reducedMotion);
    }

    _round += 1;
    if (_round >= _rounds) {
      add(TimerComponent(
        period: 1.3,
        removeOnFinish: true,
        onTick: () => completeGame(voice: VoiceInstruction.greatJob),
      ));
    } else {
      add(TimerComponent(period: 1.9, removeOnFinish: true, onTick: _startRound));
    }
  }

  _GiveItem? _freeItem() {
    for (final item in _items) {
      if (item.draggable && !item.isDragging) return item;
    }
    return null;
  }

  // --------------------------------------------------------------- hints

  @override
  void showHint() {
    if (isCompleted || _roundResolved) return;
    _hintStreak += 1;
    if (_hintStreak >= 3) {
      _hintStreak = 0;
      autoAssist();
      return;
    }
    final item = _freeItem();
    if (item == null) return;
    item.pulseHint(reducedMotion: reducedMotion);
    _basket.showHighlight();
    milo?.pointTowards(_basket.position.x >= size.x / 2 ? 1 : -1);
  }

  @override
  void repeatInstruction() {
    if (isCompleted || _roundResolved) return;
    _sayPrompt();
  }

  @override
  void highlightTarget() {
    if (isCompleted || _roundResolved) return;
    _basket.showHighlight();
    repeatInstruction();
  }

  @override
  void autoAssist() {
    if (isCompleted || _roundResolved || _pending >= _target) return;
    final item = _freeItem();
    if (item == null) return;
    _basket.hideHighlight();
    _noteIncoming();
    item.snapToZone(_basket, onArrived: () => _onItemArrived(item));
  }
}

/// One draggable tray item: a soft round card with the item's art on it.
class _GiveItem extends DraggableItem implements OpacityProvider {
  _GiveItem({
    required this.item,
    required int index,
    this.highContrast = false,
    required super.position,
    required super.size,
  }) : super(itemId: '${item.id}#$index');

  final ContentItem item;
  final bool highContrast;

  double _opacity = 1;
  bool _fading = false;
  GlowHighlight? _glow;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) => _opacity = value.clamp(0.0, 1.0);

  /// Gentle attention pulse (a still glow when motion is reduced).
  void pulseHint({required bool reducedMotion}) {
    if (reducedMotion) {
      if (_glow != null && _glow!.isMounted) return;
      final glow = GlowHighlight(radius: size.length / 2 + 16)
        ..position = Vector2(size.x / 2, size.y / 2);
      glow.add(TimerComponent(
        period: 1.8,
        removeOnFinish: true,
        onTick: glow.dismiss,
      ));
      _glow = glow;
      add(glow);
      return;
    }
    add(GentleEffects.attentionPulse());
  }

  /// Nestles into its little spot inside the basket after snapping.
  void settleIntoBasket({
    required int index,
    required int columns,
    required Vector2 basketSize,
    required bool reducedMotion,
  }) {
    final col = index % columns;
    final row = index ~/ columns;
    final dx = columns == 1
        ? 0.0
        : (col - (columns - 1) / 2) * (basketSize.x * 0.58 / (columns - 1));
    final dy = basketSize.y * 0.04 - row * basketSize.y * 0.14;
    final offset = Vector2(dx, dy);
    final settled = Vector2.all(0.68);
    if (reducedMotion) {
      position += offset;
      scale = settled;
      return;
    }
    add(MoveByEffect(offset, EffectController(duration: 0.24, curve: Curves.easeOut)));
    add(ScaleEffect.to(settled, EffectController(duration: 0.24, curve: Curves.easeOut)));
  }

  /// Softly fades away (spare items after the basket is full).
  void fadeAway({required bool reducedMotion}) {
    if (_fading) return;
    _fading = true;
    draggable = false;
    _glow?.dismiss();
    _glow = null;
    add(OpacityEffect.fadeOut(
      EffectController(duration: reducedMotion ? 0.25 : 0.6),
      onComplete: removeFromParent,
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final needsLayer = _opacity < 1;
    if (needsLayer) {
      canvas.saveLayer(
        Rect.fromLTWH(-8, -8, size.x + 16, size.y + 16),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: _opacity),
      );
    }
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      center,
      radius,
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
    if (needsLayer) canvas.restore();
  }
}

/// The big friendly basket. Open while collecting; closes with a lid and a
/// little knob when it holds the asked-for amount.
class _BasketZone extends DropZone {
  _BasketZone({
    required super.position,
    required super.size,
    required this.highContrast,
  }) : super(zoneId: 'basket', priority: 1);

  final bool highContrast;

  bool closed = false;

  void celebrateWobble({required bool reducedMotion}) {
    if (reducedMotion) return;
    add(GentleEffects.wobble(angle: 0.05, repeats: 2));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    final outlinePaint = Paint()
      ..color = highContrast
          ? Palette.outlineStrong
          : Palette.outline.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 4 : 3
      ..strokeCap = StrokeCap.round;

    // Woven body.
    final body = Path()
      ..moveTo(w * 0.06, h * 0.18)
      ..lineTo(w * 0.94, h * 0.18)
      ..quadraticBezierTo(w * 0.97, h * 0.60, w * 0.84, h * 0.92)
      ..quadraticBezierTo(w * 0.50, h * 1.02, w * 0.16, h * 0.92)
      ..quadraticBezierTo(w * 0.03, h * 0.60, w * 0.06, h * 0.18)
      ..close();
    canvas.drawPath(body, Paint()..color = Palette.softBrown);
    final weave = Paint()
      ..color = Palette.outlineStrong.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 3; i++) {
      final y = h * (0.18 + 0.19 * i);
      final margin = w * (0.07 + 0.02 * i);
      canvas.drawPath(
        Path()
          ..moveTo(margin, y)
          ..quadraticBezierTo(w * 0.5, y + h * 0.06, w - margin, y),
        weave,
      );
    }
    canvas.drawPath(body, outlinePaint);

    // Opening (or the happy lid once the basket is full).
    final opening = Rect.fromLTWH(w * 0.04, 0, w * 0.92, h * 0.30);
    if (closed) {
      canvas.drawOval(opening, Paint()..color = Palette.peach);
      canvas.drawOval(opening, outlinePaint);
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.14),
        w * 0.05,
        Paint()..color = Palette.butter,
      );
      canvas.drawCircle(Offset(w * 0.5, h * 0.14), w * 0.05, outlinePaint);
    } else {
      canvas.drawOval(
        opening,
        Paint()..color = Palette.outlineStrong.withValues(alpha: 0.35),
      );
      canvas.drawOval(opening, outlinePaint);
    }
  }
}

/// The big friendly numeral that appears above the basket after each give.
class _CountNumeral extends PositionComponent implements OpacityProvider {
  _CountNumeral({
    required this.text,
    required super.position,
    required this.reducedMotion,
  }) : super(size: Vector2.all(112), anchor: Anchor.center, priority: 80);

  final String text;
  final bool reducedMotion;

  double _opacity = 1;
  late final TextPainter _painter;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) => _opacity = value.clamp(0.0, 1.0);

  @override
  Future<void> onLoad() async {
    _painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size.y * 0.52,
          fontWeight: FontWeight.w800,
          color: Palette.textDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (!reducedMotion) {
      scale = Vector2.zero();
      add(GentleEffects.popIn());
    }
    add(TimerComponent(
      period: reducedMotion ? 0.9 : 1.1,
      removeOnFinish: true,
      onTick: () => add(OpacityEffect.fadeOut(
        EffectController(duration: 0.35),
        onComplete: removeFromParent,
      )),
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_opacity < 1) {
      canvas.saveLayer(
        Rect.fromLTWH(-10, -10, size.x + 20, size.y + 20),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: _opacity),
      );
    }
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      center,
      size.x / 2,
      Paint()..color = Palette.butter.withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      center,
      size.x / 2,
      Paint()
        ..color = Palette.outline.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _painter.paint(
      canvas,
      center - Offset(_painter.width / 2, _painter.height / 2),
    );
    if (_opacity < 1) canvas.restore();
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
    canvas.drawCircle(Offset(size.x * 0.9, size.y * 0.12), 40,
        Paint()..color = Palette.butter.withValues(alpha: 0.8));
    canvas.drawOval(
      Rect.fromLTWH(-size.x * 0.2, size.y * 0.80, size.x * 1.4, size.y * 0.5),
      Paint()..color = Palette.meadow.withValues(alpha: 0.7),
    );
  }
}
