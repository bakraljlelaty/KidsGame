import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/accessibility/app_haptics.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/palette.dart';
import '../../features/learning_path/path_progress.dart';
import '../../features/profiles/profile_controller.dart';
import '../../features/progress/progress_controller.dart';
import '../../features/rewards/reward_overlay.dart';
import '../../features/rewards/rewards_controller.dart';
import '../../features/session_control/session_controller.dart';
import '../../features/session_control/sleepy_screen.dart';
import '../../features/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/exit_slider.dart';
import 'activity_registry.dart';
import 'activity_spec.dart';
import 'game_context.dart';
import 'toddler_game.dart';

/// Hosts one academy activity (engine-based or bespoke): builds the
/// GameContext, records subject progress, marks the learning-path node,
/// runs the reward flow and respects session wind-down.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.spec});

  final ActivitySpec spec;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late final ToddlerGame _game;
  late final DateTime _startedAt;
  var _completed = false;
  var _reward = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    final profile = context.read<ProfileController>();
    final settings = context.read<SettingsController>().settings;
    final progress = context.read<ProgressController>();
    final audio = context.read<AudioManager>();

    final gameContext = GameContext(
      stageConfig: profile.stageConfig,
      bandConfig: profile.bandConfig,
      spec: widget.spec,
      languageCode: settings.languageCode,
      audio: audio,
      haptics: AppHaptics(enabled: settings.hapticsEnabled),
      reducedMotion: settings.reducedMotion,
      highContrast: settings.highContrast,
      leftHanded: settings.leftHanded,
      onHintShown: () => progress.recordActivityHint(widget.spec.subject),
      onCompleted: _onGameCompleted,
    );

    _game = ActivityRegistry.create(widget.spec, gameContext);
    scheduleMicrotask(() {
      if (widget.spec.engine == ActivityEngine.bespoke) {
        final bespokeGame = widget.spec.bespokeGame;
        if (bespokeGame != null) progress.recordGameStarted(bespokeGame);
      } else {
        progress.recordActivityStarted(widget.spec.subject);
      }
    });
  }

  void _onGameCompleted() {
    if (_completed) return;
    _completed = true;
    _reward = _runRewardFlow();
  }

  Future<void> _runRewardFlow() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final rewards = context.read<RewardsController>();
    final progress = context.read<ProgressController>();
    final pathProgress = context.read<PathProgressController>();
    final band = context.read<ProfileController>().profile.band;
    final spec = widget.spec;

    // Free play also gently advances the path: a completed node counts
    // wherever it was played from.
    final completedUnit =
        await pathProgress.markNodeCompleted(band, spec);

    final reward = spec.engine == ActivityEngine.bespoke &&
            spec.bespokeGame != null
        ? await rewards.awardCompletion(spec.bespokeGame!)
        : await rewards.awardActivityCompletion(
            spec.subject,
            unitCompleted: completedUnit != null,
          );

    if (spec.engine == ActivityEngine.bespoke && spec.bespokeGame != null) {
      await progress.recordCompletion(
        spec.bespokeGame!,
        skills: spec.skills,
        usedHints: _game.usedAnyHint,
        playTime: DateTime.now().difference(_startedAt),
      );
    } else {
      await progress.recordActivityCompletion(
        spec.subject,
        skills: spec.skills,
        usedHints: _game.usedAnyHint,
        playTime: DateTime.now().difference(_startedAt),
      );
    }
    if (!mounted) return;

    final reducedMotion =
        context.read<SettingsController>().settings.reducedMotion;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, _, _) => RewardOverlay(
        reward: reward,
        reducedMotion: reducedMotion,
        onDone: () => Navigator.of(dialogContext).pop(),
      ),
    );
    if (!mounted) return;
    await _leaveAfterActivity();
  }

  Future<void> _leaveAfterActivity() async {
    final session = context.read<SessionController>();
    if (session.phase == SessionPhase.windDown) {
      await session.finishWindDown();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const SleepyScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>().settings;
    unawaited(_reward);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Palette.cream,
        body: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _game)),
            SafeArea(
              child: Align(
                alignment: settings.leftHanded
                    ? Alignment.topLeft
                    : Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ExitSlider(
                    semanticLabel: l10n.semanticsBack,
                    highContrast: settings.highContrast,
                    onExit: () {
                      if (!_completed) Navigator.of(context).maybePop();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
