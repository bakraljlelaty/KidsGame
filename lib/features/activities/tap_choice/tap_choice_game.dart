import 'dart:math' as math;

import 'package:flame/components.dart';
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

/// REFERENCE ENGINE — TapChoice.
///
/// Three modes selected by the ActivitySpec params:
///  * default: "find the `named item`" among distractors
///  * oddOneOut=1: several identical items and one different — tap the odd one
///  * countMode=1 (numbers pack): a cluster of small objects appears; tap
///    the numeral that says how many
///
/// Rounds per play: params['rounds'] (default 3). Choice count comes from
/// the age band. All content resolves from the spec's content pack.
class TapChoiceGame extends ToddlerGame {
  TapChoiceGame(super.gameContext);

  static final math.Random _random = math.Random();

  late final List<ContentItem> _pool;
  late final int _rounds;
  late final bool _oddOneOut;
  late final bool _countMode;

  int _round = 0;
  ItemTile? _correctTile;
  VoiceInstruction? _prompt;
  final List<ItemTile> _tiles = [];
  final List<Component> _countCluster = [];
  int _clusterCount = 0;

  @override
  Color backgroundColor() => Palette.cream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final spec = gameContext.spec;
    _pool = spec == null || spec.contentPack.isEmpty
        ? ItemCatalog.colors
        : spec.contentPack == 'letters'
            ? ItemCatalog.lettersFor(gameContext.languageCode)
            : ItemCatalog.pack(spec.contentPack);
    _rounds = gameContext.param('rounds', 3);
    _oddOneOut = gameContext.param('oddOneOut', 0) == 1;
    _countMode = gameContext.param('countMode', 0) == 1;

    await add(_SoftBackground(size: size.clone()));
    await addMilo();
    say(_oddOneOut || _countMode
        ? VoiceInstruction.findIt
        : VoiceInstruction.findIt);
    add(TimerComponent(
      period: 1.6,
      removeOnFinish: true,
      onTick: _startRound,
    ));
  }

  int get _choiceCount {
    final band = gameContext.bandConfig;
    final wanted = gameContext.param('choices', band.choiceCount);
    return wanted.clamp(2, math.max(2, _pool.length));
  }

  void _clearRound() {
    for (final tile in _tiles) {
      tile.removeFromParent();
    }
    _tiles.clear();
    for (final c in _countCluster) {
      c.removeFromParent();
    }
    _countCluster.clear();
  }

  void _startRound() {
    if (isCompleted) return;
    _clearRound();

    if (_countMode) {
      _startCountRound();
    } else if (_oddOneOut) {
      _startOddOneOutRound();
    } else {
      _startFindRound();
    }
    startHintCountdown();
  }

  // ------------------------------------------------------------- rounds

  void _layoutTiles(List<ContentItem> items, ContentItem correct) {
    final tileSize = (math.min(size.x, size.y) * 0.3)
            .clamp(110.0, 210.0) *
        gameContext.bandConfig.itemScale;
    final count = items.length;
    final centerY = _countMode ? size.y * 0.66 : size.y * 0.5;
    final spacing = math.min(
        tileSize * 1.35, (size.x - 240) / math.max(1, count));
    final startX = size.x / 2 - spacing * (count - 1) / 2;

    for (var i = 0; i < count; i++) {
      final item = items[i];
      final tile = ItemTile(
        item: item,
        highContrast: highContrast,
        position: Vector2(startX + spacing * i, centerY),
        size: Vector2.all(tileSize),
        onPressed: (t) => _onTileTapped(t as ItemTile),
      );
      if (item.id == correct.id) _correctTile = tile;
      _tiles.add(tile);
      add(tile);
      tile.scale = Vector2.zero();
      tile.add(GentleEffects.popIn());
    }
  }

  void _startFindRound() {
    final options = [..._pool]..shuffle(_random);
    final chosen = options.take(_choiceCount).toList();
    final correct = chosen[_random.nextInt(chosen.length)];
    _prompt = correct.nameVoice;
    _layoutTiles(chosen, correct);
    _sayPrompt();
  }

  void _startOddOneOutRound() {
    final options = [..._pool]..shuffle(_random);
    final base = options[0];
    final odd = options[1];
    final tiles = [
      for (var i = 0; i < _choiceCount - 1; i++)
        ContentItem(
          id: '${base.id}#$i',
          artId: base.artId,
          color: base.color,
          glyph: base.glyph,
          nameVoice: base.nameVoice,
        ),
      odd,
    ]..shuffle(_random);
    _prompt = VoiceInstruction.findIt;
    _layoutTiles(tiles, odd);
    _sayPrompt();
  }

  void _startCountRound() {
    final band = gameContext.bandConfig;
    _clusterCount = 1 + _random.nextInt(band.countingMax.clamp(1, 5));
    // Cluster of small objects to count (drawn from the food pack).
    final clusterItem =
        ItemCatalog.food[_random.nextInt(ItemCatalog.food.length)];
    final iconSize = 72.0 * band.itemScale;
    final spacing = iconSize * 1.15;
    final startX = size.x / 2 - spacing * (_clusterCount - 1) / 2;
    for (var i = 0; i < _clusterCount; i++) {
      final icon = _ClusterIcon(
        item: clusterItem,
        position: Vector2(startX + spacing * i, size.y * 0.26),
        size: Vector2.all(iconSize),
      );
      _countCluster.add(icon);
      add(icon);
    }

    // Numeral choices; correct = cluster count.
    final numerals = ItemCatalog.numbers
        .where((n) => (n.value ?? 0) <= band.countingMax)
        .toList();
    final correct =
        numerals.firstWhere((n) => n.value == _clusterCount);
    final wrong = [...numerals]..removeWhere((n) => n.value == _clusterCount);
    wrong.shuffle(_random);
    final chosen = [correct, ...wrong.take(_choiceCount - 1)]
      ..shuffle(_random);
    _prompt = correct.nameVoice;
    _layoutTiles(chosen, correct);
    say(VoiceInstruction.countIntro);
  }

  void _sayPrompt() {
    say(VoiceInstruction.findIt);
    final named = _prompt;
    if (named != null && named != VoiceInstruction.findIt) {
      add(TimerComponent(
        period: 1.3,
        removeOnFinish: true,
        onTick: () => say(named),
      ));
    }
  }

  // -------------------------------------------------------- interaction

  void _onTileTapped(ItemTile tile) {
    if (isCompleted || tile.consumed) return;
    if (tile == _correctTile) {
      _onCorrect(tile);
    } else {
      tile.add(GentleEffects.wobble());
      handleWrongAttempt();
    }
  }

  void _onCorrect(ItemTile tile) {
    tile.consumed = true;
    registerCorrectAction();
    stopHintCountdown();
    playEffect(SoundEffect.pop);
    add(SparkleBurst(
      at: tile.position.clone(),
      color: tile.item.color ?? Palette.starGold,
      reducedMotion: reducedMotion,
    ));
    tile.add(GentleEffects.happyHop());
    if (_random.nextBool()) milo?.laugh();

    _round += 1;
    if (_round >= _rounds) {
      add(TimerComponent(
        period: 0.9,
        removeOnFinish: true,
        onTick: () => completeGame(voice: VoiceInstruction.greatJob),
      ));
    } else {
      add(TimerComponent(
        period: 1.2,
        removeOnFinish: true,
        onTick: _startRound,
      ));
    }
  }

  // --------------------------------------------------------------- hints

  @override
  void showHint() {
    final correct = _correctTile;
    if (correct == null) return;
    correct.pulse();
    milo?.pointTowards(correct.position.x >= size.x / 2 ? 1 : -1);
  }

  @override
  void repeatInstruction() {
    final named = _prompt;
    if (named != null) say(named);
  }

  @override
  void highlightTarget() {
    _correctTile?.showHighlight();
    repeatInstruction();
  }

  @override
  void autoAssist() {
    final correct = _correctTile;
    if (correct == null || correct.consumed) return;
    correct.showHighlight();
    _onCorrect(correct);
  }
}

/// A large tappable content tile (rounded card + ItemArt drawing).
class ItemTile extends TapTarget {
  ItemTile({
    required this.item,
    this.highContrast = false,
    required super.position,
    required Vector2 super.size,
    super.onPressed,
  }) : super(targetId: item.id);

  final ContentItem item;
  final bool highContrast;
  bool consumed = false;

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.22),
    );
    canvas.drawRRect(
        rect,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92));
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

class _ClusterIcon extends PositionComponent {
  _ClusterIcon({
    required this.item,
    required super.position,
    required Vector2 super.size,
  }) : super(anchor: Anchor.center);

  final ContentItem item;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    ItemArt.paint(canvas, Size(size.x, size.y), item);
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
  }
}
