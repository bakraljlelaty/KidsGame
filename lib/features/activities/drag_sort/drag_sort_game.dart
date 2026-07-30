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

/// DragSort — drag scattered items into 2-3 big open baskets.
///
/// The sorting criterion adapts to the content pack:
///  * 'colors'  — bins are colours (label: a blob of that colour)
///  * 'shapes'  — bins are distinct shapes (matched by artId)
///  * 'animals' / 'food' — bins are group values (label: the group's
///    first item)
/// Any pack falls through the same detection (group -> artId -> colour ->
/// id) and an unusable/empty pack falls back to shapes, so a child never
/// meets a broken board.
///
/// Bin count and item count come from the age band
/// ([BandConfig.sortBinCount] / [BandConfig.sortItemCount]) with optional
/// 'bins' / 'items' spec params. One fully sorted board completes the
/// activity; a spec may opt into extra boards with 'rounds'.
class DragSortGame extends ToddlerGame {
  DragSortGame(super.gameContext);

  static final math.Random _random = math.Random();

  late final List<ContentItem> _pool;
  late final _SortCriterion _criterion;
  late final int _rounds;

  int _boardsDone = 0;
  int _copySerial = 0;
  bool _boardReady = false;

  final List<_SortableItem> _items = [];
  final List<_BasketZone> _bins = [];
  _SortableItem? _lastTried;

  @override
  Color backgroundColor() => Palette.cream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    var pool = _resolvePool();
    var criterion = _detectCriterion(pool);
    if (_distinctKeys(pool, criterion).length < 2) {
      pool = ItemCatalog.shapes;
      criterion = _SortCriterion.art;
    }
    _pool = pool;
    _criterion = criterion;
    _rounds = gameContext.param('rounds', 1).clamp(1, 5);

    await add(_SoftBackground(size: size.clone()));
    await addMilo();
    say(VoiceInstruction.sortIntro);
    add(TimerComponent(
      period: 1.5,
      removeOnFinish: true,
      onTick: _startBoard,
    ));
  }

  // ------------------------------------------------------- content setup

  List<ContentItem> _resolvePool() {
    final spec = gameContext.spec;
    if (spec == null || spec.contentPack.isEmpty) return ItemCatalog.shapes;
    final pack = spec.contentPack == 'letters'
        ? ItemCatalog.lettersFor(gameContext.languageCode)
        : ItemCatalog.pack(spec.contentPack);
    return pack.isEmpty ? ItemCatalog.shapes : pack;
  }

  static _SortCriterion _detectCriterion(List<ContentItem> pool) {
    final groups = pool.map((i) => i.group).whereType<String>().toSet();
    if (groups.length >= 2) return _SortCriterion.group;
    final arts = pool.map((i) => i.artId).toSet();
    if (arts.length >= 2) return _SortCriterion.art;
    final colors = pool.map((i) => i.color).whereType<Color>().toSet();
    if (colors.length >= 2) return _SortCriterion.color;
    return _SortCriterion.id;
  }

  static String _keyFor(ContentItem item, _SortCriterion criterion) =>
      switch (criterion) {
        _SortCriterion.group => item.group ?? item.artId,
        _SortCriterion.art => item.artId,
        _SortCriterion.color =>
          'c${(item.color ?? Palette.coral).toARGB32()}',
        _SortCriterion.id => item.id,
      };

  String _keyOf(ContentItem item) => _keyFor(item, _criterion);

  static List<String> _distinctKeys(
      List<ContentItem> pool, _SortCriterion criterion) {
    final seen = <String>[];
    for (final item in pool) {
      final key = _keyFor(item, criterion);
      if (!seen.contains(key)) seen.add(key);
    }
    return seen;
  }

  ContentItem _copyOf(ContentItem base) {
    _copySerial += 1;
    return ContentItem(
      id: '${base.id}#$_copySerial',
      artId: base.artId,
      color: base.color,
      nameVoice: base.nameVoice,
      value: base.value,
      group: base.group,
      glyph: base.glyph,
    );
  }

  // ------------------------------------------------------------- boards

  void _clearBoard() {
    _boardReady = false;
    _lastTried = null;
    for (final item in _items) {
      item.removeFromParent();
    }
    _items.clear();
    for (final bin in _bins) {
      bin.hideHighlight();
      bin.removeFromParent();
    }
    _bins.clear();
  }

  void _startBoard() {
    if (isCompleted) return;
    _clearBoard();

    final band = gameContext.bandConfig;
    final keys = _distinctKeys(_pool, _criterion)..shuffle(_random);
    final binCount = math.max(
      2,
      math.min(
        gameContext.param('bins', band.sortBinCount),
        math.min(3, keys.length),
      ),
    );
    final binKeys = keys.take(binCount).toList();
    final itemCount =
        gameContext.param('items', band.sortItemCount).clamp(binCount, 12);

    // Content per bin: every real pack item first, gentle duplicates after.
    final basesByKey = <String, List<ContentItem>>{
      for (final key in binKeys) key: [],
    };
    for (final item in _pool) {
      basesByKey[_keyOf(item)]?.add(item);
    }
    final labelByKey = <String, ContentItem>{
      for (final key in binKeys) key: basesByKey[key]!.first,
    };
    final remainingByKey = <String, List<ContentItem>>{
      for (final key in binKeys)
        key: List.of(basesByKey[key]!)..shuffle(_random),
    };
    ContentItem takeFor(String key) {
      final remaining = remainingByKey[key]!;
      if (remaining.isNotEmpty) return remaining.removeLast();
      final bases = basesByKey[key]!;
      return _copyOf(bases[_random.nextInt(bases.length)]);
    }

    final picks = <({ContentItem item, String key})>[
      for (final key in binKeys) (item: takeFor(key), key: key),
    ];
    while (picks.length < itemCount) {
      final key = binKeys[_random.nextInt(binKeys.length)];
      picks.add((item: takeFor(key), key: key));
    }
    picks.shuffle(_random);

    // ---- baskets along the bottom (clear of Milo's corner) ----
    final miloOnLeft = !gameContext.leftHanded;
    final left = miloOnLeft ? 200.0 : 36.0;
    final right = miloOnLeft ? 36.0 : 200.0;
    final rowWidth = size.x - left - right;
    final binHeight = (size.y * 0.26).clamp(110.0, 190.0);
    final binWidth = (rowWidth / binCount * 0.72).clamp(110.0, 250.0);
    final gap = rowWidth / binCount;
    final binCenterY = size.y - binHeight / 2 - 20;

    for (var i = 0; i < binCount; i++) {
      final key = binKeys[i];
      final zone = _BasketZone(
        binKey: key,
        labelItem: labelByKey[key]!,
        highContrast: highContrast,
        position: Vector2(left + gap * (i + 0.5), binCenterY),
        size: Vector2(binWidth, binHeight),
      );
      zone.acceptTest = (dragged) {
        if (dragged is! _SortableItem) return false;
        _lastTried = dragged;
        return !dragged.sorted && dragged.binKey == key;
      };
      zone.onAccepted =
          (dragged) => _onSorted(dragged as _SortableItem, zone);
      _bins.add(zone);
      add(zone);
      if (!reducedMotion) {
        zone.scale = Vector2.zero();
        zone.add(GentleEffects.popIn());
      }
    }

    // ---- items scattered in the upper play area ----
    const regionTop = 70.0;
    final regionBottom = binCenterY - binHeight / 2 - 34;
    final regionHeight = math.max(90.0, regionBottom - regionTop);
    const sideMargin = 90.0;
    final regionWidth = math.max(200.0, size.x - sideMargin * 2);
    final rows = (itemCount > 6 && regionHeight >= 270) ? 3 : 2;
    final cols = (itemCount / rows).ceil();
    final cellWidth = regionWidth / cols;
    final cellHeight = regionHeight / rows;
    final desired = math.min(size.x, size.y) * 0.24 * band.itemScale;
    final itemSide = math
        .min(desired, math.min(cellWidth, cellHeight) * 0.82)
        .clamp(64.0, 160.0);

    final slots = <Vector2>[
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++)
          Vector2(
            sideMargin + cellWidth * (c + 0.5),
            regionTop + cellHeight * (r + 0.5),
          ),
    ]..shuffle(_random);

    for (var i = 0; i < picks.length; i++) {
      final pick = picks[i];
      final jitter = Vector2(
        (_random.nextDouble() - 0.5) * cellWidth * 0.16,
        (_random.nextDouble() - 0.5) * cellHeight * 0.16,
      );
      final item = _SortableItem(
        item: pick.item,
        binKey: pick.key,
        highContrast: highContrast,
        position: slots[i % slots.length] + jitter,
        size: Vector2.all(itemSide),
      );
      _items.add(item);
      add(item);
      if (!reducedMotion) {
        item.scale = Vector2.zero();
        item.add(GentleEffects.popIn());
      }
    }

    _boardReady = true;
    startHintCountdown();
  }

  // -------------------------------------------------------- interaction

  void _onSorted(_SortableItem item, _BasketZone zone) {
    if (item.sorted || isCompleted) return;
    item.sorted = true;
    if (identical(_lastTried, item)) _lastTried = null;
    zone.hideHighlight();
    registerCorrectAction();

    add(SparkleBurst(
      at: zone.position - Vector2(0, zone.size.y * 0.28),
      color: item.item.color ?? Palette.starGold,
      reducedMotion: reducedMotion,
      count: 8,
    ));
    zone.happySquash(reducedMotion: reducedMotion);
    item.nestleInto(zone, slot: zone.fillCount, reducedMotion: reducedMotion);
    zone.fillCount += 1;

    final remaining = _items.where((i) => !i.sorted).length;
    if (remaining == 0) {
      stopHintCountdown();
      add(TimerComponent(
        period: 1.0,
        removeOnFinish: true,
        onTick: _onBoardDone,
      ));
    } else {
      if (_random.nextBool()) {
        add(TimerComponent(
          period: 0.6,
          removeOnFinish: true,
          onTick: () => say(VoiceInstruction.sortNext),
        ));
      }
      if (_random.nextInt(3) == 0) milo?.laugh();
    }
  }

  void _onBoardDone() {
    _boardsDone += 1;
    if (_boardsDone >= _rounds) {
      completeGame(voice: VoiceInstruction.greatJob);
    } else {
      playEffect(SoundEffect.chimeSuccess);
      say(VoiceInstruction.sortIntro);
      add(TimerComponent(
        period: 1.2,
        removeOnFinish: true,
        onTick: _startBoard,
      ));
    }
  }

  // --------------------------------------------------------------- hints

  _BasketZone? _zoneFor(_SortableItem item) {
    for (final zone in _bins) {
      if (zone.binKey == item.binKey) return zone;
    }
    return null;
  }

  /// The unsorted item closest to its own basket (least effort to finish).
  _SortableItem? _hintItem() {
    _SortableItem? best;
    var bestDistance = double.infinity;
    for (final item in _items) {
      if (item.sorted || item.isDragging) continue;
      final zone = _zoneFor(item);
      if (zone == null) continue;
      final distance = item.position.distanceTo(zone.position);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = item;
      }
    }
    return best;
  }

  @override
  void showHint() {
    if (!_boardReady) return;
    final item = _hintItem();
    if (item == null) return;
    _zoneFor(item)?.showHighlight();
    if (!reducedMotion) item.add(GentleEffects.attentionPulse(repeats: 2));
    final miloX = milo?.position.x ?? size.x / 2;
    milo?.pointTowards(item.position.x >= miloX ? 1 : -1);
  }

  @override
  void repeatInstruction() => say(VoiceInstruction.sortIntro);

  @override
  void highlightTarget() {
    if (!_boardReady) return;
    final tried = _lastTried;
    final item =
        (tried != null && !tried.sorted) ? tried : _hintItem();
    if (item == null) return;
    _zoneFor(item)?.showHighlight();
    if (!reducedMotion && !item.isDragging) {
      item.add(GentleEffects.attentionPulse(repeats: 2));
    }
    repeatInstruction();
  }

  @override
  void autoAssist() {
    if (isCompleted || !_boardReady) return;
    final tried = _lastTried;
    final item = (tried != null && !tried.sorted && !tried.isDragging)
        ? tried
        : _hintItem();
    if (item == null) return;
    final zone = _zoneFor(item);
    if (zone == null) return;
    zone.showHighlight();
    // Wait for any bounce-home motion to settle, then glide it in for the
    // child exactly like an accepted drop.
    add(TimerComponent(
      period: reducedMotion ? 0.3 : 0.6,
      removeOnFinish: true,
      onTick: () {
        if (isCompleted || item.sorted || item.isDragging || !item.isMounted) {
          zone.hideHighlight();
          return;
        }
        item.snapToZone(zone, onArrived: () => zone.onAccepted?.call(item));
      },
    ));
  }
}

enum _SortCriterion { group, art, color, id }

/// A scattered pack item the child drags into its basket.
class _SortableItem extends DraggableItem {
  _SortableItem({
    required this.item,
    required this.binKey,
    this.highContrast = false,
    required super.position,
    required super.size,
  }) : super(itemId: item.id);

  final ContentItem item;
  final String binKey;
  final bool highContrast;
  bool sorted = false;

  /// Shrinks and settles into the basket opening after being accepted.
  void nestleInto(DropZone zone,
      {required int slot, required bool reducedMotion}) {
    const slotOffsets = [0.0, -0.22, 0.22, -0.11, 0.11, -0.3, 0.3];
    final dx = slotOffsets[slot % slotOffsets.length] * zone.size.x;
    final target = zone.position + Vector2(dx, -zone.size.y * 0.18);
    priority = 2;
    final duration = reducedMotion ? 0.12 : 0.32;
    add(MoveToEffect(
      target,
      EffectController(duration: duration, curve: Curves.easeOut),
    ));
    add(ScaleEffect.to(
      Vector2.all(0.42),
      EffectController(duration: duration, curve: Curves.easeOut),
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Soft halo so every item reads clearly on the pastel background.
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x * 0.54,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5),
    );
    ItemArt.paint(
      canvas,
      Size(size.x, size.y),
      item,
      highContrast: highContrast,
    );
  }
}

/// A big rounded open basket labelled with a sample of what belongs in it.
class _BasketZone extends DropZone {
  _BasketZone({
    required this.binKey,
    required this.labelItem,
    this.highContrast = false,
    required super.position,
    required super.size,
  }) : super(zoneId: 'bin_$binKey');

  final String binKey;
  final ContentItem labelItem;
  final bool highContrast;

  /// How many items already nestle inside (drives their little offsets).
  int fillCount = 0;

  /// Tiny squash-and-stretch "thank you" when an item lands.
  void happySquash({required bool reducedMotion}) {
    if (reducedMotion) return;
    add(SequenceEffect([
      ScaleEffect.to(
        Vector2(1.07, 0.90),
        EffectController(duration: 0.10, curve: Curves.easeOut),
      ),
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.18, curve: Curves.easeOut),
      ),
    ]));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    final outline = Paint()
      ..color = highContrast
          ? Palette.outlineStrong
          : Palette.outline.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 4.0 : 3.0
      ..strokeCap = StrokeCap.round;

    // Woven body: a soft trapezoid with a rounded bottom.
    final body = Path()
      ..moveTo(w * 0.07, h * 0.30)
      ..lineTo(w * 0.16, h * 0.86)
      ..quadraticBezierTo(w * 0.50, h * 1.02, w * 0.84, h * 0.86)
      ..lineTo(w * 0.93, h * 0.30)
      ..close();
    canvas.drawPath(body, Paint()..color = Palette.peach);
    final weave = Paint()
      ..color = Palette.softBrown.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.11, h * 0.46)
        ..quadraticBezierTo(w * 0.50, h * 0.54, w * 0.89, h * 0.46),
      weave,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.14, h * 0.64)
        ..quadraticBezierTo(w * 0.50, h * 0.72, w * 0.86, h * 0.64),
      weave,
    );
    canvas.drawPath(body, outline);

    // Open top: rim ellipse with a shaded inside.
    final rim = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.30),
      width: w * 0.86,
      height: h * 0.18,
    );
    canvas.drawOval(
        rim, Paint()..color = Palette.softBrown.withValues(alpha: 0.30));
    canvas.drawOval(rim, outline);

    // Label badge: a small sample of what belongs in this basket.
    final badgeRadius = math.min(w, h) * 0.26;
    final badgeCenter = Offset(w * 0.50, h * 0.62);
    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.94),
    );
    canvas.drawCircle(badgeCenter, badgeRadius, outline);
    final artSide = badgeRadius * 1.5;
    canvas.save();
    canvas.translate(
        badgeCenter.dx - artSide / 2, badgeCenter.dy - artSide / 2);
    ItemArt.paint(
      canvas,
      Size(artSide, artSide),
      labelItem,
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
      Offset(size.x * 0.90, size.y * 0.12),
      40,
      Paint()..color = Palette.butter.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      Offset(size.x * 0.12, size.y * 0.20),
      26,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5),
    );
  }
}
