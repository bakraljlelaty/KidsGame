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

/// MemoryPairs — classic flip-and-find pairs, toddler-gentle.
///
/// A centered grid of face-down cards (soft star-pattern backs). Tapping a
/// card flips it; two matching face-up cards stay up with sparkles and a
/// happy voice, two different cards simply turn back over after a moment —
/// a memory miss is never a mistake, so there is no negative feedback of
/// any kind and [handleWrongAttempt] is never called.
///
/// Pair count comes from the age band (`memoryPairCount`, 2–6) and can be
/// overridden by the spec param 'pairs'. Content resolves from the spec's
/// content pack ('letters' resolves per app language).
///
/// Help ladder (driven by the inactivity hint timer, escalating gently):
///  1. pulse a helpful face-down card while Milo points at it
///  2. peek-flip that card's partner for a second
///  3. auto-assist: flip a whole pair up and count it as found
class MemoryPairsGame extends ToddlerGame {
  MemoryPairsGame(super.gameContext);

  static final math.Random _random = math.Random();

  final List<_MemoryCard> _cards = [];
  final List<_MemoryCard> _selected = [];

  late final int _pairCount;
  int _matchedPairs = 0;

  /// Blocks taps while two flipped cards resolve (match or turn back).
  bool _resolving = false;

  /// Blocks taps while a hint peek-flip is showing.
  bool _peeking = false;

  /// 0 = pulse, 1 = peek partner, 2 = auto-assist (then wraps around).
  int _hintLevel = 0;

  /// The card the last hint pulsed, so the peek can reveal its partner.
  _MemoryCard? _lastHintCard;

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
    if (pool.isEmpty) pool = ItemCatalog.shapes;

    final band = gameContext.bandConfig;
    _pairCount = gameContext
        .param('pairs', band.memoryPairCount)
        .clamp(2, math.min(6, pool.length));

    await add(_SoftBackground(size: size.clone()));
    await addMilo();
    say(VoiceInstruction.memoryIntro);

    final items = [...pool]..shuffle(_random);
    final chosen = items.take(_pairCount).toList();
    add(TimerComponent(
      period: 0.7,
      removeOnFinish: true,
      onTick: () => _dealBoard(chosen),
    ));
  }

  // --------------------------------------------------------------- board

  void _dealBoard(List<ContentItem> chosen) {
    if (isCompleted) return;

    final band = gameContext.bandConfig;
    final cardCount = _pairCount * 2;
    final rows = cardCount <= 10 ? 2 : 3;
    final cols = (cardCount / rows).ceil();

    const gap = 18.0;
    final minSide = 110.0 * band.itemScale;
    final maxSide = 200.0 * band.itemScale;
    final availW = size.x * 0.84;
    final availH = size.y * 0.72;
    final side = math
        .min(
          (availW - gap * (cols - 1)) / cols,
          (availH - gap * (rows - 1)) / rows,
        )
        .clamp(minSide, maxSide);

    final boardH = rows * side + (rows - 1) * gap;
    final topY = size.y * 0.5 - boardH / 2 + side / 2;

    final deck = <ContentItem>[...chosen, ...chosen]..shuffle(_random);
    for (var i = 0; i < deck.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      // Center a final row that is not completely filled.
      final inThisRow = math.min(cols, deck.length - row * cols);
      final rowW = inThisRow * side + (inThisRow - 1) * gap;
      final startX = (size.x - rowW) / 2 + side / 2;

      final card = _MemoryCard(
        item: deck[i],
        index: i,
        highContrast: highContrast,
        position: Vector2(startX + col * (side + gap), topY + row * (side + gap)),
        size: Vector2.all(side),
        onPressed: (t) => _onCardTapped(t as _MemoryCard),
      );
      _cards.add(card);
      add(card);
      if (!reducedMotion) {
        card.scale = Vector2.zero();
        card.add(GentleEffects.popIn());
      }
    }
    startHintCountdown();
  }

  // --------------------------------------------------------- interaction

  void _onCardTapped(_MemoryCard card) {
    if (isCompleted || _resolving || _peeking) return;
    if (card.matched || card.faceUp || card.flipping) return;
    if (_selected.length >= 2) return;

    _lastHintCard = null;
    playEffect(SoundEffect.pop);
    _selected.add(card);
    card.flip(faceUp: true, onDone: () => _checkSelection());
  }

  void _checkSelection() {
    if (_selected.length < 2) return;
    final a = _selected[0];
    final b = _selected[1];
    if (a.flipping || b.flipping) return; // wait for the second flip

    _resolving = true;
    if (a.item.id == b.item.id) {
      _resolveMatch(a, b);
    } else {
      // A quiet moment to look at both, then they turn back over. Never a
      // mistake: no sound, no wrong-attempt escalation.
      add(TimerComponent(
        period: 0.9,
        removeOnFinish: true,
        onTick: () {
          a.flip(faceUp: false);
          b.flip(faceUp: false, onDone: () {
            _selected.clear();
            _resolving = false;
          });
        },
      ));
    }
  }

  void _resolveMatch(_MemoryCard a, _MemoryCard b) {
    a.matched = true;
    b.matched = true;
    a.enabled = false;
    b.enabled = false;
    _selected.clear();
    _matchedPairs += 1;
    _hintLevel = 0;
    _lastHintCard = null;

    registerCorrectAction();
    playEffect(SoundEffect.chimeSuccess);
    gameContext.haptics.success();
    say(VoiceInstruction.memoryPairFound);
    milo?.laugh();
    for (final card in [a, b]) {
      add(SparkleBurst(
        at: card.position.clone(),
        color: card.item.color ?? Palette.starGold,
        reducedMotion: reducedMotion,
      ));
      if (!reducedMotion) card.add(GentleEffects.happyHop(height: 14));
    }
    _resolving = false;

    if (_matchedPairs >= _pairCount) {
      stopHintCountdown();
      add(TimerComponent(
        period: 1.1,
        removeOnFinish: true,
        onTick: () => completeGame(voice: VoiceInstruction.greatJob),
      ));
    }
  }

  // --------------------------------------------------------------- hints

  /// A face-down card worth drawing attention to: the partner of the one
  /// face-up card if there is one, otherwise any card of an unmatched pair.
  _MemoryCard? _hintCandidate() {
    if (_selected.length == 1) {
      final partner = _partnerOf(_selected.first);
      if (partner != null) return partner;
    }
    final faceDown = _cards
        .where((c) => !c.matched && !c.faceUp && !c.flipping)
        .toList();
    if (faceDown.isEmpty) return null;
    return faceDown[_random.nextInt(faceDown.length)];
  }

  _MemoryCard? _partnerOf(_MemoryCard card) {
    for (final other in _cards) {
      if (other != card && !other.matched && other.item.id == card.item.id) {
        return other;
      }
    }
    return null;
  }

  @override
  void showHint() {
    if (isCompleted || _resolving || _peeking) return;
    switch (_hintLevel) {
      case 0:
        _hintLevel = 1;
        final card = _hintCandidate();
        if (card == null) return;
        _lastHintCard = card;
        say(VoiceInstruction.memoryIntro);
        card.hintPulse();
        milo?.pointTowards(card.position.x >= size.x / 2 ? 1 : -1);
      case 1:
        _hintLevel = 2;
        highlightTarget();
      default:
        _hintLevel = 0;
        autoAssist();
    }
  }

  @override
  void repeatInstruction() => say(VoiceInstruction.memoryIntro);

  /// Peek-flips the partner of the last-hinted (or face-up) card for about
  /// a second, then turns it back over.
  @override
  void highlightTarget() {
    if (isCompleted || _resolving || _peeking) return;

    _MemoryCard? source = _lastHintCard;
    if (source == null || source.matched || source.faceUp) {
      source = _selected.length == 1 ? _selected.first : _hintCandidate();
    }
    if (source == null) return;
    final partner = _partnerOf(source);
    if (partner == null || partner.faceUp || partner.flipping) return;

    _peeking = true;
    playEffect(SoundEffect.chimeSoft);
    milo?.pointTowards(partner.position.x >= size.x / 2 ? 1 : -1);
    partner.flip(faceUp: true, onDone: () {
      add(TimerComponent(
        period: 1.0,
        removeOnFinish: true,
        onTick: () {
          partner.flip(faceUp: false, onDone: () => _peeking = false);
        },
      ));
    });
  }

  /// Flips both cards of one unmatched pair and counts it as found, so no
  /// child ever gets stuck.
  @override
  void autoAssist() {
    if (isCompleted || _resolving || _peeking) return;

    var first = _selected.isEmpty ? null : _selected.first;
    first ??= _hintCandidate();
    if (first == null) return;
    final partner = _partnerOf(first);
    if (partner == null) return;

    _resolving = true;
    final a = first;
    playEffect(SoundEffect.chimeSoft);
    a.flip(faceUp: true, onDone: () {
      partner.flip(faceUp: true, onDone: () {
        _selected.clear();
        _resolveMatch(a, partner);
      });
    });
  }
}

/// One memory card: a rounded tile that is a soft star-pattern back when
/// face-down and the item's ItemArt when face-up. Flips with a horizontal
/// squash (instant under reduced motion).
class _MemoryCard extends TapTarget {
  _MemoryCard({
    required this.item,
    required int index,
    required this.highContrast,
    required super.position,
    required super.size,
    super.onPressed,
  }) : super(targetId: '${item.id}#$index', hitPadding: 8);

  final ContentItem item;
  final bool highContrast;

  /// Logical state (set as soon as a flip is requested).
  bool faceUp = false;
  bool matched = false;
  bool flipping = false;

  /// Which side is currently drawn (swaps at the flip midpoint).
  bool _showFace = false;

  Effect? _pulse;

  void hintPulse() {
    if (flipping) return;
    if (game.reducedMotion) {
      showHighlight();
      game.add(TimerComponent(
        period: 2.0,
        removeOnFinish: true,
        onTick: hideHighlight,
      ));
      return;
    }
    if (_pulse != null && _pulse!.isMounted) return;
    _pulse = GentleEffects.attentionPulse();
    add(_pulse!);
  }

  void _clearHintFx() {
    if (_pulse != null && _pulse!.isMounted) {
      _pulse!.removeFromParent();
      scale.setFrom(Vector2.all(1));
    }
    _pulse = null;
    hideHighlight();
  }

  void flip({required bool faceUp, VoidCallback? onDone}) {
    _clearHintFx();
    if (this.faceUp == faceUp) {
      onDone?.call();
      return;
    }
    this.faceUp = faceUp;

    if (game.reducedMotion) {
      _showFace = faceUp;
      onDone?.call();
      return;
    }

    flipping = true;
    add(ScaleEffect.to(
      Vector2(0.04, 1),
      EffectController(duration: 0.18, curve: Curves.easeIn),
      onComplete: () {
        _showFace = faceUp;
        add(ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.18, curve: Curves.easeOut),
          onComplete: () {
            flipping = false;
            onDone?.call();
          },
        ));
      },
    ));
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.2),
    );

    if (_showFace) {
      canvas.drawRRect(
        rrect,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.94),
      );
      canvas.save();
      final inset = size.x * 0.13;
      canvas.translate(inset, inset);
      ItemArt.paint(
        canvas,
        Size(size.x - inset * 2, size.y - inset * 2),
        item,
        highContrast: highContrast,
      );
      canvas.restore();
    } else {
      canvas.drawRRect(rrect, Paint()..color = Palette.babyBlue);
      final starPaint = Paint()
        ..color = Palette.cream.withValues(alpha: 0.85);
      final s = size.x;
      canvas.drawPath(_star(Offset(s * 0.5, s * 0.5), s * 0.16), starPaint);
      canvas.drawPath(_star(Offset(s * 0.24, s * 0.26), s * 0.08), starPaint);
      canvas.drawPath(_star(Offset(s * 0.76, s * 0.26), s * 0.08), starPaint);
      canvas.drawPath(_star(Offset(s * 0.24, s * 0.76), s * 0.08), starPaint);
      canvas.drawPath(_star(Offset(s * 0.76, s * 0.76), s * 0.08), starPaint);
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = matched
            ? Palette.starGold
            : highContrast
                ? Palette.outlineStrong
                : Palette.outline.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highContrast || matched ? 4 : 3,
    );
    super.render(canvas);
  }

  static Path _star(Offset center, double radius) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.5;
      final angle = -math.pi / 2 + i * math.pi / points;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
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
      Offset(size.x * 0.9, size.y * 0.12),
      40,
      Paint()..color = Palette.butter.withValues(alpha: 0.8),
    );
  }
}
