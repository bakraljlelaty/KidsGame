import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_manager.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/palette.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/game/game_registry.dart';
import '../../shared/game/mini_game_screen.dart';
import '../../shared/models/game_id.dart';
import '../../shared/widgets/world_icon.dart';
import '../parent_dashboard/game_access.dart';
import '../parent_dashboard/game_access_controller.dart';
import '../progress/progress_controller.dart';
import '../rewards/rewards_controller.dart';
import '../session_control/session_controller.dart';
import '../session_control/sleepy_screen.dart';
import '../settings/settings_controller.dart';

/// World selection: six friendly locations, one per mini-game. Tiles are
/// icon-first (no reading), very large, and locked games simply rest under
/// a cloud — they are never presented as failure.
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  SessionController? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioManager>().playInstruction(VoiceInstruction.chooseGame);
      _session = context.read<SessionController>()
        ..addListener(_onSessionChanged);
    });
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    // Time ran out while the child is on the map (not mid-activity):
    // wind down right away, calmly.
    final session = _session;
    if (session != null &&
        session.phase == SessionPhase.windDown &&
        mounted &&
        ModalRoute.of(context)?.isCurrent == true) {
      session.finishWindDown();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const SleepyScreen()),
      );
    }
  }

  void _openGame(GameId id) {
    AppNavigation.push<void>(
      context,
      (_) => MiniGameScreen(gameId: id),
      reducedMotion: context.read<SettingsController>().settings.reducedMotion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final access = context.watch<GameAccessController>();
    final progress = context.watch<ProgressController>().data;
    final rewards = context.watch<RewardsController>().data;
    final settings = context.watch<SettingsController>().settings;

    final guidedGame = access.access.playMode == PlayMode.guided
        ? access.currentGuidedGame(progress)
        : null;
    final decorations = rewards.decorationPoints.clamp(0, 12);

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Palette.skyDay, Palette.meadow],
            ),
          ),
          child: SafeArea(
            child: Semantics(
              label: l10n.semanticsWorldMap,
              child: Stack(
                children: [
                  // Decoration flowers grow with participation.
                  for (var i = 0; i < decorations; i++)
                    Positioned(
                      left: 24.0 + (i * 67) % 320,
                      bottom: 8.0 + (i * 23) % 40,
                      child: Icon(
                        Icons.local_florist_rounded,
                        size: 22,
                        color: [
                          Palette.softPink,
                          Palette.softYellow,
                          Palette.lavender,
                        ][i % 3]
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final definition in GameRegistry.all)
                                _WorldTile(
                                  definition: definition,
                                  title: definition.title(l10n),
                                  stars:
                                      rewards.starsFor(definition.id),
                                  enabled: access.canPlay(
                                      definition.id, progress),
                                  resting: guidedGame != null &&
                                      guidedGame != definition.id,
                                  lockedLabel: l10n.worldLocked,
                                  highContrast: settings.highContrast,
                                  onTap: () => _openGame(definition.id),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: settings.leftHanded
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Semantics(
                        label: l10n.semanticsHome,
                        button: true,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: settings.highContrast
                                    ? Palette.outlineStrong
                                    : Palette.outline
                                        .withValues(alpha: 0.4),
                                width: settings.highContrast ? 3 : 2,
                              ),
                            ),
                            child: const Icon(Icons.home_rounded,
                                size: 44, color: Palette.textDark),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldTile extends StatelessWidget {
  const _WorldTile({
    required this.definition,
    required this.title,
    required this.stars,
    required this.enabled,
    required this.resting,
    required this.lockedLabel,
    required this.highContrast,
    required this.onTap,
  });

  final GameDefinition definition;
  final String title;
  final int stars;
  final bool enabled;

  /// Guided mode: game exists but it's another game's turn.
  final bool resting;
  final String lockedLabel;
  final bool highContrast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !resting;
    final tile = AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: active ? 1 : 0.45,
      child: Container(
        width: 190,
        height: 168,
        decoration: BoxDecoration(
          color: active ? Colors.white : Palette.disabled,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: highContrast
                ? Palette.outlineStrong
                : Colors.white.withValues(alpha: 0.9),
            width: highContrast ? 3 : 4,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: Palette.outlineStrong.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WorldIcon(gameId: definition.id, size: 84),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Palette.textSoft,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    Icons.star_rounded,
                    size: 22,
                    color: i < stars.clamp(0, 3)
                        ? Palette.starGold
                        : Palette.disabled,
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    return Semantics(
      label: active ? title : '$title. $lockedLabel',
      button: active,
      child: GestureDetector(
        onTap: active ? onTap : null,
        child: tile,
      ),
    );
  }
}
