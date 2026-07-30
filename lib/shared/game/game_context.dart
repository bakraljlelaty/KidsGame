import '../../core/accessibility/app_haptics.dart';
import '../../core/audio/audio_manager.dart';
import '../models/age_band.dart';
import '../models/development_stage.dart';
import 'activity_spec.dart';

/// Everything an activity needs from the outside world.
///
/// Games never touch persistence, providers or navigation — the
/// ActivityScreen/MiniGameScreen wrappers own those, which keeps game logic
/// pure and unit-testable.
class GameContext {
  GameContext({
    required this.stageConfig,
    required this.bandConfig,
    required this.audio,
    this.spec,
    this.languageCode = 'en',
    AppHaptics? haptics,
    this.reducedMotion = false,
    this.highContrast = false,
    this.leftHanded = false,
    this.onHintShown,
    this.onCompleted,
  }) : haptics = haptics ?? AppHaptics(enabled: false);

  /// v1 tuning used by the six bespoke mini-games.
  final StageConfig stageConfig;

  /// Academy tuning used by the activity engines.
  final BandConfig bandConfig;

  /// The activity being played (null when a bespoke game is launched
  /// directly from Milo's World).
  final ActivitySpec? spec;

  /// Current app language ('en'/'ar') — engines use it to resolve the
  /// letters content pack.
  final String languageCode;

  final GameAudio audio;
  final AppHaptics haptics;
  final bool reducedMotion;
  final bool highContrast;
  final bool leftHanded;

  /// Reported so parents can see how often help appeared (neutral wording).
  final void Function()? onHintShown;

  /// The activity finished; the wrapper runs the reward flow.
  final void Function()? onCompleted;

  /// Spec param with band-config fallback handled by callers.
  int param(String key, int fallback) => spec?.paramOr(key, fallback) ?? fallback;
}
