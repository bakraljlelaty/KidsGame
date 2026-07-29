import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../shared/characters/milo_state.dart';
import '../../shared/characters/milo_view.dart';
import '../../shared/widgets/sticker_art.dart';
import 'rewards_controller.dart';

/// Full-screen celebration after an activity: Milo dances, one star pops in
/// and the earned sticker is shown. Auto-continues after a few seconds or on
/// a tap anywhere — a toddler can never get stuck here.
class RewardOverlay extends StatefulWidget {
  const RewardOverlay({
    super.key,
    required this.reward,
    required this.onDone,
    this.reducedMotion = false,
  });

  final CompletionReward reward;
  final VoidCallback onDone;
  final bool reducedMotion;

  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _autoContinue;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.reducedMotion ? 200 : 700),
    )..forward();
    _autoContinue = Timer(const Duration(milliseconds: 3600), _finish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _autoContinue?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _autoContinue?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: _controller,
      curve: widget.reducedMotion ? Curves.easeOut : Curves.elasticOut,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _finish(),
      child: Container(
        color: Palette.butter.withValues(alpha: 0.92),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MiloView(
                state: MiloState.dancing,
                size: const Size(180, 210),
                reducedMotion: widget.reducedMotion,
              ),
              const SizedBox(width: 32),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: scale,
                    child: const _StarBadge(),
                  ),
                  const SizedBox(height: 20),
                  if (widget.reward.sticker != null)
                    ScaleTransition(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.outlineStrong
                                  .withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: StickerArtView(
                          art: widget.reward.sticker!.art,
                          size: 96,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarBadge extends StatelessWidget {
  const _StarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.star_rounded, color: Palette.starGold, size: 84),
      ),
    );
  }
}
