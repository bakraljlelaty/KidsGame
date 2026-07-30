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
              // Living meadow backdrop: drifting clouds, sun rays,
              // layered hills, flowers, a wandering butterfly.
              Positioned.fill(
                child: _LivingMeadow(reducedMotion: settings.reducedMotion),
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

/// Slow, calm scenery animation for the home screen. One 60-second loop:
/// clouds drift across, sun rays breathe, a butterfly wanders. Under
/// reduced motion everything renders as a single still frame.
class _LivingMeadow extends StatefulWidget {
  const _LivingMeadow({required this.reducedMotion});

  final bool reducedMotion;

  @override
  State<_LivingMeadow> createState() => _LivingMeadowState();
}

class _LivingMeadowState extends State<_LivingMeadow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    if (!widget.reducedMotion) _controller.repeat();
  }

  @override
  void didUpdateWidget(_LivingMeadow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.reducedMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _MeadowPainter(t: _controller.value),
        ),
      ),
    );
  }
}

class _MeadowPainter extends CustomPainter {
  _MeadowPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tau = t * 2 * 3.14159265;

    // Sun with breathing halo and soft rays.
    final sun = Offset(w * 0.86, h * 0.16);
    final halo = 58 + 6 * _wave(tau, 3);
    canvas.drawCircle(
        sun, halo, Paint()..color = Palette.butter.withValues(alpha: 0.25));
    for (var i = 0; i < 8; i++) {
      final angle = i * 3.14159265 / 4 + tau * 0.5;
      final rayStart = sun +
          Offset(58 * _cosA(angle), 58 * _sinA(angle));
      final rayEnd = sun +
          Offset((72 + 4 * _wave(tau, 2)) * _cosA(angle),
              (72 + 4 * _wave(tau, 2)) * _sinA(angle));
      canvas.drawLine(
        rayStart,
        rayEnd,
        Paint()
          ..color = Palette.butter.withValues(alpha: 0.55)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(sun, 46, Paint()..color = Palette.butter);
    canvas.drawCircle(
        sun.translate(-12, -12), 14,
        Paint()..color = Colors.white.withValues(alpha: 0.4));

    // Drifting clouds (two layers, wrapping).
    void cloud(double phase, double y, double scale, double alpha) {
      final x = ((t * 0.6 + phase) % 1.2 - 0.1) * w;
      final c = Offset(x, h * y);
      final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
      canvas.drawOval(
          Rect.fromCenter(center: c, width: 130 * scale, height: 48 * scale),
          paint);
      canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(-42 * scale, 12 * scale),
              width: 90 * scale,
              height: 40 * scale),
          paint);
      canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(44 * scale, 14 * scale),
              width: 90 * scale,
              height: 42 * scale),
          paint);
    }

    cloud(0.0, 0.14, 1.0, 0.9);
    cloud(0.45, 0.26, 0.7, 0.75);
    cloud(0.8, 0.08, 0.55, 0.6);

    // Layered hills.
    canvas.drawOval(
      Rect.fromLTWH(-w * 0.3, h * 0.78, w * 1.0, h * 0.5),
      Paint()..color = Palette.softGreen.withValues(alpha: 0.55),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.4, h * 0.82, w * 0.9, h * 0.5),
      Paint()..color = Palette.softGreen.withValues(alpha: 0.7),
    );
    final meadow = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.9)
      ..quadraticBezierTo(w * 0.5, h * 0.8, w, h * 0.9)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(meadow, Paint()..color = Palette.meadow);

    // Flowers along the meadow edge.
    for (var i = 0; i < 7; i++) {
      final fx = w * (0.08 + i * 0.14);
      final fy = h * (0.9 - 0.012 * _wave(i.toDouble(), 1));
      final sway = 2.5 * _wave(tau + i, 1);
      final color = const [
        Palette.softPink,
        Palette.softYellow,
        Palette.lavender,
      ][i % 3];
      for (var p = 0; p < 5; p++) {
        final angle = p * 2 * 3.14159265 / 5 + sway * 0.05;
        canvas.drawCircle(
          Offset(fx + 7 * _cosA(angle) + sway, fy + 7 * _sinA(angle)),
          4.5,
          Paint()..color = color,
        );
      }
      canvas.drawCircle(Offset(fx + sway, fy), 3.5,
          Paint()..color = Palette.butter);
    }

    // A wandering butterfly on a lazy figure-eight.
    final bx = w * (0.32 + 0.2 * _sinA(tau));
    final by = h * (0.3 + 0.1 * _sinA(2 * tau));
    final flap = _wave(tau * 30, 1).abs();
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bx + side * 8 * (0.5 + 0.5 * flap), by),
          width: 14 * (0.5 + 0.5 * flap),
          height: 11,
        ),
        Paint()..color = Palette.softPink.withValues(alpha: 0.9),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset(bx, by), width: 4, height: 12),
      Paint()..color = Palette.outlineStrong.withValues(alpha: 0.7),
    );
  }

  static double _wave(double x, double periods) =>
      _sinA(x * periods);

  static double _sinA(double a) {
    a = a % 6.283185307;
    if (a > 3.14159265) a -= 6.283185307;
    // Bhaskara approximation keeps this dependency-free and smooth.
    final sign = a < 0 ? -1.0 : 1.0;
    a = a.abs();
    return sign * 16 * a * (3.14159265 - a) /
        (49.348 - 4 * a * (3.14159265 - a));
  }

  static double _cosA(double a) => _sinA(a + 1.5707963);

  @override
  bool shouldRepaint(_MeadowPainter oldDelegate) => oldDelegate.t != t;
}
