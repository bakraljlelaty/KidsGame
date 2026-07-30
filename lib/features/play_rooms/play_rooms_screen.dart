import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../content/activity_definitions.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/game/activity_screen.dart';
import '../../shared/game/activity_spec.dart';
import '../../shared/models/subject.dart';
import '../../shared/models/subject_style.dart';
import '../../shared/widgets/subject_icon.dart';
import '../profiles/profile_controller.dart';
import '../settings/settings_controller.dart';
import '../world_map/world_map_screen.dart';

/// Free play: one room per concept area, each holding 5–8 activities.
class PlayRoomsScreen extends StatefulWidget {
  const PlayRoomsScreen({super.key});

  @override
  State<PlayRoomsScreen> createState() => _PlayRoomsScreenState();
}

class _PlayRoomsScreenState extends State<PlayRoomsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<AudioManager>()
          .playInstruction(VoiceInstruction.roomsIntro);
    });
  }

  String _subjectName(AppLocalizations l10n, Subject subject) =>
      switch (subject) {
        Subject.colors => l10n.subjectColors,
        Subject.shapes => l10n.subjectShapes,
        Subject.animals => l10n.subjectAnimals,
        Subject.food => l10n.subjectFood,
        Subject.numbers => l10n.subjectNumbers,
        Subject.letters => l10n.subjectLetters,
        Subject.art => l10n.subjectArt,
        Subject.milosWorld => l10n.subjectMilosWorld,
      };

  void _openRoom(Subject subject) {
    final reducedMotion =
        context.read<SettingsController>().settings.reducedMotion;
    if (subject == Subject.milosWorld) {
      AppNavigation.push<void>(
        context,
        (_) => const WorldMapScreen(),
        reducedMotion: reducedMotion,
      );
    } else {
      AppNavigation.push<void>(
        context,
        (_) => SubjectRoomScreen(subject: subject),
        reducedMotion: reducedMotion,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>().settings;
    final band = context.watch<ProfileController>().profile.band;
    final subjects = ActivityDefinitions.subjectsFor(band);

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Palette.lavender, Palette.cream],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final subject in subjects)
                        Semantics(
                          label: _subjectName(l10n, subject),
                          button: true,
                          child: GestureDetector(
                            onTap: () => _openRoom(subject),
                            child: _RoomDoor(
                              subject: subject,
                              name: _subjectName(l10n, subject),
                              languageCode: settings.languageCode,
                              highContrast: settings.highContrast,
                            ),
                          ),
                        ),
                    ],
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

/// One subject's activities in free play (all unlocked, replayable).
class SubjectRoomScreen extends StatelessWidget {
  const SubjectRoomScreen({super.key, required this.subject});

  final Subject subject;

  IconData _engineIcon(ActivityEngine engine) => switch (engine) {
        ActivityEngine.tapChoice => Icons.touch_app_rounded,
        ActivityEngine.dragSort => Icons.move_down_rounded,
        ActivityEngine.shadowMatch => Icons.filter_none_rounded,
        ActivityEngine.memoryPairs => Icons.style_rounded,
        ActivityEngine.patternComplete => Icons.more_horiz_rounded,
        ActivityEngine.countAndGive => Icons.exposure_plus_1_rounded,
        ActivityEngine.traceShape => Icons.gesture_rounded,
        ActivityEngine.freePaint => Icons.brush_rounded,
        ActivityEngine.bespoke => Icons.sports_esports_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>().settings;
    final specs = ActivityDefinitions.forSubject(subject);

    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Palette.skyDay, Palette.cream],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final spec in specs)
                        Semantics(
                          label: spec.id,
                          button: true,
                          child: GestureDetector(
                            onTap: () => AppNavigation.push<void>(
                              context,
                              (_) => ActivityScreen(spec: spec),
                              reducedMotion: settings.reducedMotion,
                            ),
                            child: Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    subject.accentSoft,
                                    subject.accent,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: settings.highContrast
                                      ? Palette.outlineStrong
                                      : Colors.white,
                                  width: settings.highContrast ? 3 : 5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: subject.accent
                                        .withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _engineIcon(spec.engine),
                                size: 54,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: settings.leftHanded
                      ? Alignment.topRight
                      : Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Semantics(
                      label: l10n.semanticsBack,
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
                          child: const Icon(Icons.arrow_back_rounded,
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

/// A subject room drawn as a friendly little house door: colored arched
/// roof, white body with the subject icon, rounded name plate.
class _RoomDoor extends StatelessWidget {
  const _RoomDoor({
    required this.subject,
    required this.name,
    required this.languageCode,
    required this.highContrast,
  });

  final Subject subject;
  final String name;
  final String languageCode;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final accent = subject.accent;
    return Container(
      width: 170,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: highContrast ? Palette.outlineStrong : accent,
          width: highContrast ? 3 : 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Arched roof band.
          Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent, subject.accentSoft],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Center(
              child: Container(
                width: 26,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SubjectIcon(
                subject: subject,
                size: 66,
                languageCode: languageCode,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              name,
              style: AppTheme.childLabel.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
