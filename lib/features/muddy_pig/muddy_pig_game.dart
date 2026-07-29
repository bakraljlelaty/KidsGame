import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/audio/voice_catalog.dart';
import '../../core/theme/palette.dart';
import '../../shared/components/gentle_effects.dart';
import '../../shared/components/tap_target.dart';
import '../../shared/game/toddler_game.dart';

/// PLACEHOLDER implementation so the app is playable end-to-end while the
/// full mini-game is developed. Tap the star to finish the activity.
class MuddyPigGame extends ToddlerGame {
  MuddyPigGame(super.gameContext);

  TapTarget? _star;

  @override
  Color backgroundColor() => Palette.cream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addMilo();
    say(VoiceInstruction.welcome);

    _star = TapTarget(
      targetId: 'star',
      position: Vector2(size.x / 2, size.y / 2),
      size: Vector2.all(160 * stage.itemScale),
      paintItem: (canvas, size) {
        final paint = Paint()..color = Palette.starGold;
        canvas.drawCircle(
            Offset(size.x / 2, size.y / 2), size.x / 2, paint);
      },
      onPressed: (_) {
        registerCorrectAction();
        add(SparkleBurst(
            at: _star!.position.clone(), reducedMotion: reducedMotion));
        completeGame();
      },
    );
    await add(_star!);
    startHintCountdown();
  }

  @override
  void showHint() {
    _star?.pulse();
    milo?.pointTowards(1);
  }

  @override
  void repeatInstruction() => say(VoiceInstruction.welcome);

  @override
  void highlightTarget() => _star?.showHighlight();

  @override
  void autoAssist() {
    _star?.showHighlight();
    _star?.pulse();
  }
}
