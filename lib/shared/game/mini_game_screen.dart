import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/accessibility/app_haptics.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/palette.dart';
import '../../features/progress/progress_controller.dart';
import '../../features/rewards/reward_overlay.dart';
import '../../features/rewards/rewards_controller.dart';
import '../../features/session_control/session_controller.dart';
import '../../features/session_control/sleepy_screen.dart';
import '../../features/profiles/profile_controller.dart';
import '../../features/settings/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../models/development_stage.dart';
import '../models/game_id.dart';
import 'game_context.dart';
import 'game_registry.dart';
import 'toddler_game.dart';

/// Hosts one mini-game: builds the GameContext from app state, records
/// progress, runs the reward flow on completion and respects session
/// wind-down ("finish the current mini-game, then stop").
class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({super.key, required this.gameId});

  final GameId gameId;

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
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
      stageConfig: StageConfig.of(profile.profile.stage),
      bandConfig: profile.bandConfig,
      languageCode: settings.languageCode,
      audio: audio,
      haptics: AppHaptics(enabled: settings.hapticsEnabled),
      reducedMotion: settings.reducedMotion,
      highContrast: settings.highContrast,
      leftHanded: settings.leftHanded,
      onHintShown: () => progress.recordHintShown(widget.gameId),
      onCompleted: _onGameCompleted,
    );

    _game = GameRegistry.of(widget.gameId).create(gameContext);
    // Deferred: recording notifies ProgressController listeners (the world
    // map watches it), which must not happen while this route is building.
    scheduleMicrotask(() => progress.recordGameStarted(widget.gameId));
  }

  void _onGameCompleted() {
    if (_completed) return;
    _completed = true;
    // Called from the Flame update loop; hop to the widget layer.
    _reward = _runRewardFlow();
  }

  Future<void> _runRewardFlow() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final rewards = context.read<RewardsController>();
    final progress = context.read<ProgressController>();
    final definition = GameRegistry.of(widget.gameId);

    final reward = await rewards.awardCompletion(widget.gameId);
    await progress.recordCompletion(
      widget.gameId,
      skills: definition.skills,
      usedHints: _game.usedAnyHint,
      playTime: DateTime.now().difference(_startedAt),
    );
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

    // Game scenes are never mirrored for RTL locales.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Palette.cream,
        body: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _game)),
            // Big, always-available way home (top corner opposite Milo).
            SafeArea(
              child: Align(
                alignment: settings.leftHanded
                    ? Alignment.topLeft
                    : Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _BackBubble(
                    semanticLabel: l10n.semanticsBack,
                    highContrast: settings.highContrast,
                    onPressed: () {
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

class _BackBubble extends StatelessWidget {
  const _BackBubble({
    required this.onPressed,
    required this.semanticLabel,
    this.highContrast = false,
  });

  final VoidCallback onPressed;
  final String semanticLabel;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: highContrast
                  ? Palette.outlineStrong
                  : Palette.outline.withValues(alpha: 0.4),
              width: highContrast ? 3 : 2,
            ),
          ),
          child: const Icon(
            Icons.home_rounded,
            size: 44,
            color: Palette.textDark,
          ),
        ),
      ),
    );
  }
}
