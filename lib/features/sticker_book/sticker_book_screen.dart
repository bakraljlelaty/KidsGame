import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_manager.dart';
import '../../core/audio/sound_effects.dart';
import '../../core/theme/palette.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/sticker_art.dart';
import '../rewards/rewards_controller.dart';
import '../rewards/sticker_catalog.dart';
import 'sticker_book_controller.dart';

/// Open-ended offline sticker book: earned stickers live in a tray and can
/// be dragged onto three simple scenes. Placement persists locally; there is
/// no sharing, no gallery access, no goals and no way to do it wrong.
class StickerBookScreen extends StatefulWidget {
  const StickerBookScreen({super.key});

  @override
  State<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends State<StickerBookScreen> {
  String _sceneId = StickerScene.meadow.id;
  final GlobalKey _sceneKey = GlobalKey();

  void _placeAt(StickerDef sticker, Offset globalOffset) {
    final box = _sceneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalOffset);
    final rel = Offset(
      (local.dx / box.size.width).clamp(0.0, 1.0),
      (local.dy / box.size.height).clamp(0.0, 1.0),
    );
    context.read<AudioManager>().playEffect(SoundEffect.ding);
    context
        .read<StickerBookController>()
        .placeSticker(sticker.id, _sceneId, rel.dx, rel.dy);
  }

  void _moveTo(int index, Offset globalOffset) {
    final box = _sceneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalOffset);
    if (local.dx < 0 || local.dy < 0 ||
        local.dx > box.size.width || local.dy > box.size.height) {
      // Dragged off the scene: back to the tray.
      context.read<StickerBookController>().removePlacement(index);
      return;
    }
    context.read<StickerBookController>().movePlacement(
          index,
          local.dx / box.size.width,
          local.dy / box.size.height,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rewards = context.watch<RewardsController>();
    final book = context.watch<StickerBookController>();
    final earned = rewards.earnedStickers;

    final placements = book.data.placements;

    return Scaffold(
      backgroundColor: Palette.cream,
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          child: Row(
            children: [
              // Tray.
              Container(
                width: 170,
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Semantics(
                      label: l10n.semanticsBack,
                      button: true,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Palette.butter,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 4),
                          ),
                          child: const Icon(Icons.home_rounded,
                              size: 44, color: Palette.textDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: earned.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: Text(
                                  l10n.stickerTrayEmpty,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Palette.textSoft,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              children: [
                                for (final sticker in earned)
                                  Draggable<StickerDef>(
                                    data: sticker,
                                    feedback: StickerArtView(
                                        art: sticker.art, size: 80),
                                    childWhenDragging: Opacity(
                                      opacity: 0.35,
                                      child: StickerArtView(
                                          art: sticker.art, size: 64),
                                    ),
                                    onDragEnd: (details) {
                                      if (details.wasAccepted) return;
                                      _placeAt(sticker,
                                          details.offset +
                                              const Offset(40, 40));
                                    },
                                    child: StickerArtView(
                                        art: sticker.art, size: 64),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              // Scene.
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final scene in StickerScene.all)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: _SceneTab(
                              scene: scene,
                              selected: scene.id == _sceneId,
                              label: switch (scene.id) {
                                'sky' => l10n.stickerSceneSky,
                                'sea' => l10n.stickerSceneSea,
                                _ => l10n.stickerSceneMeadow,
                              },
                              onTap: () =>
                                  setState(() => _sceneId = scene.id),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(4, 0, 12, 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                key: _sceneKey,
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter:
                                          _ScenePainter(_sceneId),
                                    ),
                                  ),
                                  // Placed stickers.
                                  for (var i = 0;
                                      i < placements.length;
                                      i++)
                                    if (placements[i].sceneId ==
                                        _sceneId)
                                      Positioned(
                                        left: placements[i].x *
                                                constraints.maxWidth -
                                            40,
                                        top: placements[i].y *
                                                constraints.maxHeight -
                                            40,
                                        child: _PlacedSticker(
                                          placementIndex: i,
                                          stickerId:
                                              placements[i].stickerId,
                                          onDragEnd: (offset) =>
                                              _moveTo(i, offset),
                                        ),
                                      ),
                                  // Accept drops from the tray.
                                  Positioned.fill(
                                    child: DragTarget<StickerDef>(
                                      builder: (context, _, _) =>
                                          const SizedBox.expand(),
                                      onAcceptWithDetails: (details) =>
                                          _placeAt(details.data,
                                              details.offset +
                                                  const Offset(40, 40)),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlacedSticker extends StatelessWidget {
  const _PlacedSticker({
    required this.placementIndex,
    required this.stickerId,
    required this.onDragEnd,
  });

  final int placementIndex;
  final String stickerId;
  final void Function(Offset globalOffset) onDragEnd;

  @override
  Widget build(BuildContext context) {
    final def = StickerCatalog.byId(stickerId);
    if (def == null) return const SizedBox.shrink();
    return Draggable<int>(
      data: placementIndex,
      feedback: StickerArtView(art: def.art, size: 84),
      childWhenDragging: const SizedBox(width: 80, height: 80),
      onDragEnd: (details) =>
          onDragEnd(details.offset + const Offset(40, 40)),
      child: StickerArtView(art: def.art, size: 80),
    );
  }
}

class _SceneTab extends StatelessWidget {
  const _SceneTab({
    required this.scene,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final StickerScene scene;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (scene.id) {
      'sky' => Palette.babyBlue,
      'sea' => Palette.underwater,
      _ => Palette.meadow,
    };
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 92,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Palette.outlineStrong
                  : Colors.white.withValues(alpha: 0.8),
              width: selected ? 3 : 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.sceneId);

  final String sceneId;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (sceneId) {
      case 'sky':
        canvas.drawRect(
            rect, Paint()..color = Palette.skyDay);
        for (final cloud in const [
          Offset(0.2, 0.25),
          Offset(0.6, 0.15),
          Offset(0.8, 0.4),
        ]) {
          final c = Offset(cloud.dx * size.width, cloud.dy * size.height);
          final paint = Paint()
            ..color = Colors.white.withValues(alpha: 0.85);
          canvas.drawOval(
              Rect.fromCenter(center: c, width: 110, height: 46), paint);
          canvas.drawOval(
              Rect.fromCenter(
                  center: c.translate(-34, 10), width: 80, height: 40),
              paint);
          canvas.drawOval(
              Rect.fromCenter(
                  center: c.translate(36, 12), width: 80, height: 40),
              paint);
        }
      case 'sea':
        canvas.drawRect(rect, Paint()..color = Palette.underwater);
        final wave = Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        for (var y = 0.3; y < 1; y += 0.22) {
          final path = Path()..moveTo(0, size.height * y);
          for (var x = 0.0; x < size.width; x += 60) {
            path.quadraticBezierTo(
              x + 15, size.height * y - 12,
              x + 30, size.height * y,
            );
            path.quadraticBezierTo(
              x + 45, size.height * y + 12,
              x + 60, size.height * y,
            );
          }
          canvas.drawPath(path, wave);
        }
      default: // meadow
        canvas.drawRect(rect, Paint()..color = Palette.skyDay);
        canvas.drawOval(
          Rect.fromLTWH(-size.width * 0.2, size.height * 0.55,
              size.width * 0.9, size.height),
          Paint()..color = Palette.meadow,
        );
        canvas.drawOval(
          Rect.fromLTWH(size.width * 0.3, size.height * 0.6,
              size.width * 0.95, size.height),
          Paint()..color = Palette.softGreen,
        );
        canvas.drawCircle(
          Offset(size.width * 0.85, size.height * 0.15),
          40,
          Paint()..color = Palette.butter,
        );
    }
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.sceneId != sceneId;
}
