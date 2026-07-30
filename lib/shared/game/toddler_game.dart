import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/audio/sound_effects.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/theme/palette.dart';
import '../characters/milo_component.dart';
import '../components/draggable_item.dart';
import '../components/drop_zone.dart';
import '../models/development_stage.dart';
import 'game_context.dart';

/// Base class for every mini-game.
///
/// Provides the shared toddler-friendly systems:
///  * automatic hints after stage-dependent inactivity (repeating gently)
///  * the wrong-attempt escalation ladder: gentle bounce-back, then replay
///    the instruction, then highlight the destination, then assist
///  * drag-and-drop resolution with generous snapping
///  * Milo, voice instructions, celebration and completion flow
///
/// Games implement [showHint], [repeatInstruction], [highlightTarget] and
/// [autoAssist], and call [registerCorrectAction] / [handleWrongAttempt] /
/// [completeGame] from their interactions.
abstract class ToddlerGame extends FlameGame {
  ToddlerGame(this.gameContext) {
    pauseWhenBackgrounded = true;
  }

  final GameContext gameContext;

  StageConfig get stage => gameContext.stageConfig;
  bool get reducedMotion => gameContext.reducedMotion;
  bool get highContrast => gameContext.highContrast;

  /// Milo, added by [addMilo].
  MiloComponent? milo;

  /// Active drop zones (registered by DropZone.onMount).
  final List<DropZone> dropZones = [];

  Timer? _hintTimer;
  bool _hintsRunning = false;

  /// Whether any automatic hint appeared during this play-through.
  bool usedAnyHint = false;

  /// Consecutive wrong attempts on the current objective.
  int wrongAttempts = 0;

  bool _completed = false;
  bool get isCompleted => _completed;

  @override
  Color backgroundColor() => Palette.cream;

  // ---------------------------------------------------------------- Milo

  /// Adds Milo at the given position (defaults to a corner that respects
  /// the left-handed setting: Milo sits opposite the child's hand).
  Future<MiloComponent> addMilo({Vector2? position, double height = 150}) async {
    final miloComponent = MiloComponent(
      position: position ??
          Vector2(
            gameContext.leftHanded ? size.x - 90 : 90,
            size.y - 8,
          ),
      size: Vector2(height * 0.83, height),
      reducedMotion: reducedMotion,
    );
    milo = miloComponent;
    await add(miloComponent);
    return miloComponent;
  }

  /// Speaks an instruction (never overlapping) while Milo talks.
  void say(VoiceInstruction instruction,
      {Duration talkFor = const Duration(seconds: 2)}) {
    gameContext.audio.playInstruction(instruction);
    milo?.talk(duration: talkFor);
  }

  void playEffect(SoundEffect effect) => gameContext.audio.playEffect(effect);

  // ------------------------------------------------------------- Hints

  /// Starts (or restarts) the inactivity countdown. The hint repeats every
  /// [StageConfig.hintDelay] until the child acts or hints are stopped.
  void startHintCountdown() {
    _hintsRunning = true;
    _hintTimer = Timer(
      stage.hintDelay.inMilliseconds / 1000.0,
      onTick: _fireHint,
      repeat: true,
    )..start();
  }

  void resetHintCountdown() {
    if (_hintsRunning) {
      _hintTimer?.reset();
    } else {
      startHintCountdown();
    }
  }

  void stopHintCountdown() {
    _hintsRunning = false;
    _hintTimer?.stop();
  }

  void _fireHint() {
    if (_completed) return;
    usedAnyHint = true;
    gameContext.onHintShown?.call();
    showHint();
  }

  /// Show a gentle hint for the current objective (pulse the target, have
  /// Milo point, replay the instruction...).
  @protected
  void showHint();

  // ------------------------------------------- Wrong-attempt escalation

  /// Call whenever the child tries something that doesn't match the
  /// objective. Never shows an error symbol or plays a negative sound.
  void handleWrongAttempt({DraggableItem? item}) {
    wrongAttempts += 1;
    playEffect(SoundEffect.boingSoft);
    item?.returnHome();

    if (wrongAttempts >= AppConfig.autoAssistAfterAttempts) {
      wrongAttempts = 0;
      autoAssist();
    } else if (wrongAttempts >= AppConfig.highlightTargetAfterAttempts) {
      usedAnyHint = true;
      gameContext.onHintShown?.call();
      highlightTarget();
    } else if (wrongAttempts >= AppConfig.replayInstructionAfterAttempts) {
      repeatInstruction();
    }
  }

  /// Replay the current verbal instruction.
  @protected
  void repeatInstruction();

  /// Visually highlight the correct destination.
  @protected
  void highlightTarget();

  /// Complete (or strongly guide) the current step for the child so nobody
  /// ever gets stuck.
  @protected
  void autoAssist();

  /// Test hook: the stress-test suite drives every activity to completion
  /// through the same assistance path a stuck child would get.
  @visibleForTesting
  void assistForTesting() => autoAssist();

  /// Call after every successful step: resets the escalation ladder and the
  /// hint countdown.
  void registerCorrectAction() {
    wrongAttempts = 0;
    resetHintCountdown();
  }

  // ------------------------------------------------------ Drag and drop

  /// Finds the nearest enabled drop zone within its snap radius.
  /// Returns true when the item was consumed (snapped into a zone).
  bool resolveDrop(DraggableItem item) {
    DropZone? best;
    var bestDistance = double.infinity;
    for (final zone in dropZones) {
      if (!zone.enabled) continue;
      final distance = zone.absoluteCenter.distanceTo(item.absoluteCenter);
      if (distance <= zone.snapRadius && distance < bestDistance) {
        best = zone;
        bestDistance = distance;
      }
    }

    if (best == null) {
      // Dropped in empty space: not a mistake, just drift gently home.
      item.returnHome(playSound: false);
      return false;
    }
    if (best.accepts(item)) {
      final zone = best;
      item.snapToZone(zone, onArrived: () => zone.onAccepted?.call(item));
      gameContext.haptics.success();
      return true;
    }
    handleWrongAttempt(item: item);
    return false;
  }

  // --------------------------------------------------------- Completion

  /// Celebrate and finish the activity. Safe to call once; the reward flow
  /// (stars, sticker, return to map) is handled by the wrapper.
  void completeGame({
    VoiceInstruction voice = VoiceInstruction.greatJob,
    Duration celebration = const Duration(milliseconds: 2600),
  }) {
    if (_completed) return;
    _completed = true;
    stopHintCountdown();
    playEffect(SoundEffect.celebrate);
    gameContext.audio.playInstruction(voice);
    milo?.dance(duration: celebration);
    add(
      TimerComponent(
        period: celebration.inMilliseconds / 1000.0,
        removeOnFinish: true,
        onTick: () => gameContext.onCompleted?.call(),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hintsRunning) _hintTimer?.update(dt);
  }
}
