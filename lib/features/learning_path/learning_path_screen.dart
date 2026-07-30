import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../content/path/learning_path.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/palette.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/game/activity_screen.dart';
import '../../shared/game/activity_spec.dart';
import '../../shared/widgets/subject_icon.dart';
import '../profiles/profile_controller.dart';
import '../session_control/session_controller.dart';
import '../session_control/sleepy_screen.dart';
import '../settings/settings_controller.dart';
import 'path_progress.dart';

/// The guided learning path: units of activity bubbles that open in order.
/// Icon-first — a child never needs to read anything here.
class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  SessionController? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioManager>().playInstruction(VoiceInstruction.pathIntro);
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

  void _openNode(ActivitySpec spec) {
    AppNavigation.push<void>(
      context,
      (_) => ActivityScreen(spec: spec),
      reducedMotion:
          context.read<SettingsController>().settings.reducedMotion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>().settings;
    final band = context.watch<ProfileController>().profile.band;
    final pathProgress = context.watch<PathProgressController>();
    final units = LearningPath.unitsFor(band);
    final next = pathProgress.nextNode(band);

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
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 110, vertical: 8),
                    itemCount: units.length,
                    itemBuilder: (context, index) {
                      final unit = units[index];
                      return _UnitCard(
                        unit: unit,
                        band: band,
                        pathProgress: pathProgress,
                        nextNodeId: next?.id,
                        languageCode: settings.languageCode,
                        highContrast: settings.highContrast,
                        onOpen: _openNode,
                      );
                    },
                  ),
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
                                  : Palette.outline.withValues(alpha: 0.4),
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
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.band,
    required this.pathProgress,
    required this.nextNodeId,
    required this.languageCode,
    required this.highContrast,
    required this.onOpen,
  });

  final PathUnit unit;
  final dynamic band;
  final PathProgressController pathProgress;
  final String? nextNodeId;
  final String languageCode;
  final bool highContrast;
  final void Function(ActivitySpec spec) onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = pathProgress.unitProgress(band, unit);
    final hasBadge = pathProgress.hasUnitBadge(unit);

    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: highContrast
              ? Palette.outlineStrong
              : Colors.white,
          width: highContrast ? 3 : 4,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SubjectIcon(
                  subject: unit.subject,
                  size: 54,
                  languageCode: languageCode),
              if (hasBadge)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.emoji_events_rounded,
                      color: Palette.starGold, size: 30),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Palette.cream,
              color: Palette.starGold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final node in unit.nodes)
                  _NodeBubble(
                    spec: node,
                    completed: pathProgress.isNodeCompleted(band, node),
                    unlocked: pathProgress.isNodeUnlocked(band, node),
                    isCurrent: node.id == nextNodeId,
                    highContrast: highContrast,
                    onOpen: onOpen,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeBubble extends StatelessWidget {
  const _NodeBubble({
    required this.spec,
    required this.completed,
    required this.unlocked,
    required this.isCurrent,
    required this.highContrast,
    required this.onOpen,
  });

  final ActivitySpec spec;
  final bool completed;
  final bool unlocked;
  final bool isCurrent;
  final bool highContrast;
  final void Function(ActivitySpec spec) onOpen;

  IconData get _engineIcon => switch (spec.engine) {
        ActivityEngine.tapChoice => Icons.touch_app_rounded,
        ActivityEngine.dragSort => Icons.move_down_rounded,
        ActivityEngine.shadowMatch => Icons.filter_none_rounded,
        ActivityEngine.memoryPairs => Icons.style_rounded,
        ActivityEngine.patternComplete => Icons.more_horiz_rounded,
        ActivityEngine.countAndGive => Icons.exposure_plus_1_rounded,
        ActivityEngine.traceShape => Icons.gesture_rounded,
        ActivityEngine.bespoke => Icons.sports_esports_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final playable = unlocked || completed;
    return Semantics(
      label: spec.id,
      button: playable,
      child: GestureDetector(
        onTap: playable ? () => onOpen(spec) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: playable
                ? (completed ? Palette.mint : Palette.butter)
                : Palette.disabled,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent
                  ? Palette.coral
                  : highContrast
                      ? Palette.outlineStrong
                      : Colors.white,
              width: isCurrent ? 5 : 3,
            ),
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.star_rounded,
                    color: Palette.starGold, size: 34)
                : Icon(
                    playable ? _engineIcon : Icons.cloud_rounded,
                    color: playable
                        ? Palette.textDark
                        : Palette.textSoft,
                    size: 30,
                  ),
          ),
        ),
      ),
    );
  }
}
