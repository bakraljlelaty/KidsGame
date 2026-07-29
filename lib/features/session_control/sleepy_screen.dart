import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_manager.dart';
import '../../core/audio/sound_effects.dart';
import '../../core/audio/voice_catalog.dart';
import '../../core/theme/palette.dart';
import '../../shared/characters/milo_state.dart';
import '../../shared/characters/milo_view.dart';
import '../settings/settings_controller.dart';
import 'session_controller.dart';

/// Calm end-of-session screen: night sky, sleepy Milo, soft goodbye.
/// Returns to the home screen after a few seconds (or a tap).
class SleepyScreen extends StatefulWidget {
  const SleepyScreen({super.key});

  @override
  State<SleepyScreen> createState() => _SleepyScreenState();
}

class _SleepyScreenState extends State<SleepyScreen> {
  Timer? _leaveTimer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    final audio = context.read<AudioManager>();
    audio.playMusic(MusicTrack.lullaby);
    audio.playInstruction(VoiceInstruction.goodNight);
    audio.playEffect(SoundEffect.nightCalm);
    _leaveTimer = Timer(const Duration(seconds: 7), _leave);
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    context.read<SessionController>().acknowledgeSleepy();
    context.read<AudioManager>().playMusic(MusicTrack.calm);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _leaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        context.watch<SettingsController>().settings.reducedMotion;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _leave(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Palette.skyNight, Palette.skyEvening],
            ),
          ),
          child: Stack(
            children: [
              // Soft stars.
              for (final star in const [
                Offset(0.15, 0.2),
                Offset(0.3, 0.12),
                Offset(0.55, 0.18),
                Offset(0.72, 0.1),
                Offset(0.85, 0.24),
                Offset(0.42, 0.3),
              ])
                Align(
                  alignment: Alignment(star.dx * 2 - 1, star.dy * 2 - 1),
                  child: Icon(
                    Icons.star_rounded,
                    size: 22,
                    color: Palette.starGold.withValues(alpha: 0.8),
                  ),
                ),
              Center(
                child: MiloView(
                  state: MiloState.sleepy,
                  size: const Size(220, 260),
                  reducedMotion: reducedMotion,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
