import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_manager.dart';
import '../../core/audio/sound_effects.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/theme/palette.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/characters/milo_state.dart';
import '../../shared/characters/milo_view.dart';
import '../../shared/widgets/big_round_button.dart';
import '../learning_path/learning_path_screen.dart';
import '../parent_gate/parent_corner_gate.dart';
import '../parent_gate/pin_screen.dart';
import '../play_rooms/play_rooms_screen.dart';
import '../session_control/session_controller.dart';
import '../settings/settings_controller.dart';
import '../sticker_book/sticker_book_screen.dart';

/// The child's landing screen: Milo waves, one big play button, the sticker
/// book, and the (hidden) parent gate. No text reading required.
class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  var _greeted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  void _greet() {
    if (_greeted || !mounted) return;
    _greeted = true;
    final audio = context.read<AudioManager>();
    audio.playMusic(MusicTrack.calm);
    final session = context.read<SessionController>();
    if (session.phase == SessionPhase.blocked) {
      audio.playInstruction(VoiceInstruction.sessionOver);
    } else {
      audio.playInstruction(VoiceInstruction.welcome);
    }
  }

  void _onPlay({required bool guided}) {
    final session = context.read<SessionController>();
    final audio = context.read<AudioManager>();
    if (session.startSession()) {
      audio.playEffect(SoundEffect.chimeSoft);
      AppNavigation.push<void>(
        context,
        (_) => guided
            ? const LearningPathScreen()
            : const PlayRoomsScreen(),
        reducedMotion:
            context.read<SettingsController>().settings.reducedMotion,
      );
    } else {
      // Gently remind that it's rest time — no error state.
      audio.playInstruction(VoiceInstruction.sessionOver);
    }
  }

  void _showParentHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.touch_app_rounded, size: 36),
        title: Text(l10n.parentGateTitle),
        content: Text(
          l10n.parentGateInstruction,
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>().settings;
    final session = context.watch<SessionController>();
    final resting = session.phase == SessionPhase.blocked;

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
          child: Stack(
            children: [
              // Soft sun.
              Positioned(
                top: 30,
                right: 60,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.butter.withValues(alpha: 0.9),
                  ),
                ),
              ),
              // Meadow.
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Palette.meadow,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(120),
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: l10n.semanticsMilo,
                      child: MiloView(
                        state:
                            resting ? MiloState.sleepy : MiloState.happy,
                        size: const Size(210, 250),
                        reducedMotion: settings.reducedMotion,
                      ),
                    ),
                    const SizedBox(width: 60),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!resting)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Guided learning path.
                              BigRoundButton(
                                diameter: 150,
                                color: Palette.mint,
                                semanticLabel: l10n.semanticsPath,
                                highContrast: settings.highContrast,
                                onPressed: () => _onPlay(guided: true),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 84,
                                  color: Palette.textDark,
                                ),
                              ),
                              const SizedBox(width: 22),
                              // Free-play rooms.
                              BigRoundButton(
                                diameter: 118,
                                color: Palette.babyBlue,
                                semanticLabel: l10n.semanticsRooms,
                                highContrast: settings.highContrast,
                                onPressed: () => _onPlay(guided: false),
                                child: const Icon(
                                  Icons.apps_rounded,
                                  size: 58,
                                  color: Palette.textDark,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        BigRoundButton(
                          diameter: 104,
                          color: Palette.blush,
                          semanticLabel: l10n.semanticsStickerBook,
                          highContrast: settings.highContrast,
                          onPressed: () => AppNavigation.push<void>(
                            context,
                            (_) => const StickerBookScreen(),
                            reducedMotion: settings.reducedMotion,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 52,
                            color: Palette.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Hidden parent gate over the top corners.
              ParentCornerGate(
                semanticLabel: l10n.semanticsParentCorner,
                onUnlocked: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PinScreen()),
                ),
              ),
              // Small visible "for grown-ups" helper: explains how the
              // corner gate works. Tapping it never opens the dashboard
              // itself — it only shows readable instructions.
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Semantics(
                    label: l10n.parentGateTitle,
                    button: true,
                    child: GestureDetector(
                      onTap: () => _showParentHelp(context),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.supervisor_account_rounded,
                          size: 26,
                          color: Palette.textSoft.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
