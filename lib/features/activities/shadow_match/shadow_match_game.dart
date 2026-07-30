import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../../content/items/content_item.dart';
import '../../../content/items/item_catalog.dart';
import '../../../core/audio/voice_catalog.dart';
import '../../../core/theme/palette.dart';
import '../../../shared/components/draggable_item.dart';
import '../../../shared/components/drop_zone.dart';
import '../../../shared/components/gentle_effects.dart';
import '../../../shared/game/toddler_game.dart';
import '../../../shared/items/item_art.dart';

/// ShadowMatch — drag each object onto its silhouette.
///
/// A small set of items (age-band choice count, 2..4) appears as dark
/// translucent silhouettes spread across the upper area; the real objects
/// wait shuffled on a tray along the bottom. Dragging an object onto its
/// own shadow fills the shadow in with the real art and sparkles gently.
/// When every shadow is filled the board is done; `params['rounds']`
/// (default 3) fresh boards make one play-through.
///
/// All content resolves from the spec's content pack ('letters' resolves
/// per app language); empty or too-small packs fall back to shapes.
class ShadowMatchGame extends ToddlerGame {
  ShadowMatchGame(super.gameContext);

  static final math.Random _random = math.Random();

  late final List<ContentItem> _pool;
  late final int _rounds;

  int _round = 0;
  final List<_ShadowZone> _zones = [];
  final List<DraggableItem> _trayItems = [];

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
    if (pool.length < 2) pool = ItemCatalog.shapes;
    _pool = pool;
    _rounds = math.max(1, gameContext.param('rounds', 3));

    await add(_SoftBackground(size: size.clone()));
    await addMilo();
    say(VoiceInstruction.shadowIntro);
    add(TimerComponent(
      period: 1.6,
      removeOnFinish: true,
      onTick: _startBoard,
    ));
  }

  int get _matchCount {
    final band = gameContext.bandConfig;
    final wanted = gameContext.param('choices', band.choiceCount);
    return math.min(wanted.clamp(2, 4).toInt(), _pool.length);
  }

  // -------------------------------------------------------------- board

  void _clearBoard() {
    for (final zone in _zones) {
      zone.removeFromParent();
    }
    _zones.clear();
    for (final item in _trayItems) {
      item.removeFromParent();
    }
    _trayItems.clear();
  }

  void _startBoard() {
    if (isCompleted) return;
    _clearBoard();

    final chosen =
        ([..._pool]..shuffle(_random)).take(_matchCount).toList();
    final count = chosen.length;
    final band = gameContext.bandConfig;

    var itemSize = (math.min(size.x, size.y) * 0.26)
            .clamp(100.0, 185.0)
            .toDouble() *
        band.itemScale;
    final sideMargin = math.max(90.0, itemSize * 0.7);
    final usableW = math.max(itemSize * count, size.x - sideMargin * 2);
    itemSize = math.max(96.0, math.min(itemSize, usableW / count - 12));

    // Silhouettes spread across the upper area.
    final zoneSpacing = usableW / count;
    final baseY = size.y * 0.30;
    for (var i = 0; i < count; i++) {
      final item = chosen[i];
      final drift =
          count > 2 ? (i.isEven ? -1.0 : 1.0) * size.y * 0.045 : 0.0;
      final zone = _ShadowZone(
        item: item,
        highContrast: highContrast,
        position: Vector2(sideMargin + zoneSpacing * (i + 0.5), baseY + drift),
        size: Vector2.all(itemSize),
      );
      zone.onAccepted = (dragged) => _onMatched(zone, dragged);
      _zones.add(zone);
      add(zone);
    }

    // Real objects shuffled along the bottom tray.
    final trayOrder = [...chosen]..shuffle(_random);
    final trayY = size.y * 0.78;
    final trayMargin = math.max(170.0, itemSize * 0.9);
    final trayAvail = math.max(itemSize, size.x - trayMargin * 2);
    final traySpacing = count > 1
        ? math.min(itemSize * 1.5, trayAvail / (count - 1))
        : 0.0;
    final startX = size.x / 2 - traySpacing * (count - 1) / 2;
    for (var i = 0; i < trayOrder.length; i++) {
      final item = trayOrder[i];
      final drag = DraggableItem(
        itemId: item.id,
        position: Vector2(startX + traySpacing * i, trayY),
        size: Vector2.all(itemSize),
        paintItem: (canvas, s) => ItemArt.paint(
          canvas,
          Size(s.x, s.y),
          item,
          highContrast: highContrast,
        ),
      );
      _trayItems.add(drag);
      add(drag);
      if (!reducedMotion) {
        drag.scale = Vector2.zero();
        drag.add(GentleEffects.popIn());
      }
    }

    if (_round > 0) say(VoiceInstruction.shadowNext);
    startHintCountdown();
  }

  // -------------------------------------------------------- interaction

  void _onMatched(_ShadowZone zone, DraggableItem dragged) {
    if (zone.matched || isCompleted) return;
    zone.matched = true;
    zone.enabled = false;
    zone.hideHighlight();
    dragged.removeFromParent();
    _trayItems.remove(dragged);

    registerCorrectAction();
    add(SparkleBurst(
      at: zone.position.clone(),
      color: zone.item.color ?? Palette.starGold,
      reducedMotion: reducedMotion,
    ));
    if (!reducedMotion) {
      zone.scale = Vector2.all(0.9);
      zone.add(ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.3, curve: Curves.easeOutBack),
      ));
    }
    if (_random.nextBool()) milo?.laugh();

    final remaining = _zones.where((z) => !z.matched).length;
    if (remaining == 0) {
      _onBoardDone();
    } else {
      add(TimerComponent(
        period: 0.7,
        removeOnFinish: true,
        onTick: () {
          if (!isCompleted) say(VoiceInstruction.shadowNext);
        },
      ));
    }
  }

  void _onBoardDone() {
    stopHintCountdown();
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
        onTick: _startBoard,
      ));
    }
  }

  _ShadowZone? _zoneFor(String itemId) {
    for (final zone in _zones) {
      if (!zone.matched && zone.item.id == itemId) return zone;
    }
    return null;
  }

  /// Leftmost tray object whose shadow is still empty.
  DraggableItem? get _firstUnmatched {
    for (final item in _trayItems) {
      if (_zoneFor(item.itemId) != null) return item;
    }
    return null;
  }

  // -------------------------------------------------------------- hints

  @override
  void showHint() {
    final item = _firstUnmatched;
    if (item == null) return;
    final zone = _zoneFor(item.itemId);
    if (zone == null) return;
    if (!reducedMotion && !item.isDragging) {
      item.add(GentleEffects.attentionPulse());
    }
    zone.showHighlight();
    add(TimerComponent(
      period: 2.6,
      removeOnFinish: true,
      onTick: zone.hideHighlight,
    ));
    milo?.pointTowards(zone.position.x >= size.x / 2 ? 1 : -1);
  }

  @override
  void repeatInstruction() => say(VoiceInstruction.shadowIntro);

  @override
  void highlightTarget() {
    final item = _firstUnmatched;
    if (item == null) return;
    _zoneFor(item.itemId)?.showHighlight();
    repeatInstruction();
  }

  @override
  void autoAssist() {
    if (isCompleted) return;
    final item = _firstUnmatched;
    if (item == null || item.isDragging) return;
    final zone = _zoneFor(item.itemId);
    if (zone == null) return;
    zone.showHighlight();
    item.snapToZone(zone, onArrived: () => zone.onAccepted?.call(item));
  }
}

/// One silhouette destination. While unmatched it renders the item's art
/// masked to a dark translucent shadow; once matched it renders the real
/// item on a slightly brighter pad.
class _ShadowZone extends DropZone {
  _ShadowZone({
    required this.item,
    required this.highContrast,
    required super.position,
    required super.size,
  }) : super(zoneId: item.id) {
    acceptTest = (dragged) => dragged.itemId == item.id;
  }

  final ContentItem item;
  final bool highContrast;
  bool matched = false;

  Color _silhouetteColor() {
    final base = Color.lerp(
          item.color ?? Palette.outlineStrong,
          Palette.outlineStrong,
          0.68,
        ) ??
        Palette.outlineStrong;
    return base.withValues(alpha: highContrast ? 0.85 : 0.6);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
    final pad = RRect.fromRectAndRadius(
      bounds.inflate(6),
      Radius.circular(size.x * 0.24),
    );
    canvas.drawRRect(
      pad,
      Paint()
        ..color = const Color(0xFFFFFFFF)
            .withValues(alpha: matched ? 0.6 : 0.4),
    );
    if (matched) {
      ItemArt.paint(
        canvas,
        Size(size.x, size.y),
        item,
        highContrast: highContrast,
      );
    } else {
      canvas.saveLayer(bounds, Paint());
      ItemArt.paint(
        canvas,
        Size(size.x, size.y),
        item,
        highContrast: highContrast,
      );
      canvas.drawRect(
        bounds,
        Paint()
          ..color = _silhouetteColor()
          ..blendMode = BlendMode.srcIn,
      );
      canvas.restore();
    }
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
    canvas.drawCircle(Offset(size.x * 0.88, size.y * 0.14), 38,
        Paint()..color = Palette.butter.withValues(alpha: 0.8));
    // Soft shelf where the real objects wait.
    final shelf = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y * 0.81),
        width: size.x * 0.64,
        height: size.y * 0.22,
      ),
      const Radius.circular(28),
    );
    canvas.drawRRect(
        shelf, Paint()..color = Palette.mint.withValues(alpha: 0.35));
  }
}
