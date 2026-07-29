import '../../core/accessibility/app_haptics.dart';
import '../../core/audio/audio_manager.dart';
import '../models/development_stage.dart';

/// Everything a mini-game needs from the outside world.
///
/// Games never touch persistence, providers or navigation — the
/// MiniGameScreen wrapper owns those, which keeps game logic pure and
/// unit-testable.
class GameContext {
  GameContext({
    required this.stageConfig,
    required this.audio,
    AppHaptics? haptics,
    this.reducedMotion = false,
    this.highContrast = false,
    this.leftHanded = false,
    this.onHintShown,
    this.onCompleted,
  }) : haptics = haptics ?? AppHaptics(enabled: false);

  final StageConfig stageConfig;
  final GameAudio audio;
  final AppHaptics haptics;
  final bool reducedMotion;
  final bool highContrast;
  final bool leftHanded;

  /// Reported so parents can see how often help appeared (neutral wording).
  final void Function()? onHintShown;

  /// The activity finished; the wrapper runs the reward flow.
  final void Function()? onCompleted;
}
