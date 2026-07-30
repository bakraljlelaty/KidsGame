import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'milo_state.dart';

/// Procedural placeholder art for Milo — an original, small, round, friendly
/// animal drawn from soft shapes. Both the Flutter widget (MiloView) and the
/// Flame component (MiloComponent) call [paint], so replacing this with
/// sprite sheets later happens in exactly one place per host.
///
/// The drawing lives in a 100 x 120 design box scaled to the given size.
class MiloPainter {
  MiloPainter._();

  static void paint(
    Canvas canvas,
    Size size, {
    required MiloState state,
    required double time,
    bool reducedMotion = false,
    bool wearsHelmet = false,
    int pointDirection = 1,
  }) {
    canvas.save();
    final scale = math.min(size.width / 100, size.height / 120);
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 120 * scale) / 2,
    );
    canvas.scale(scale);

    final motion = reducedMotion ? 0.25 : 1.0;
    final t = time;

    // Body bounce & sway.
    double bounce = math.sin(t * 2 * math.pi / 1.8) * 1.6 * motion;
    double sway = 0;
    switch (state) {
      case MiloState.dancing:
        bounce = math.sin(t * 2 * math.pi / 0.55) * 4.5 * motion;
        sway = math.sin(t * 2 * math.pi / 1.1) * 6 * motion;
      case MiloState.happy:
      case MiloState.laughing:
        bounce = math.sin(t * 2 * math.pi / 0.8) * 3.2 * motion;
      case MiloState.sleepy:
        bounce = math.sin(t * 2 * math.pi / 3.4) * 1.0 * motion;
      default:
        break;
    }

    canvas.translate(sway, bounce);

    final outline = Paint()
      ..color = Palette.outlineStrong.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final bodyPaint = Paint()..color = Palette.miloBody;
    final earPaint = Paint()..color = Palette.miloEar;
    final bellyPaint = Paint()..color = Palette.miloBelly;

    // Soft top-light shading gives the flat shapes gentle volume.
    final bodyShaded = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.45),
        radius: 1.25,
        colors: [Color(0xFFFBD9B4), Palette.miloBody, Color(0xFFEBB183)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(const Rect.fromLTWH(18, 36, 64, 68));

    // Tail: a soft curl behind the body.
    final tail = Path()
      ..moveTo(24, 92)
      ..quadraticBezierTo(8, 96, 12, 82)
      ..quadraticBezierTo(14, 74, 22, 78);
    canvas.drawPath(tail, earPaint);
    canvas.drawPath(tail, outline);

    // Feet.
    canvas.drawOval(Rect.fromCenter(
        center: const Offset(38, 104), width: 18, height: 10), earPaint);
    canvas.drawOval(Rect.fromCenter(
        center: const Offset(62, 104), width: 18, height: 10), earPaint);

    // Ears (leaf-shaped, inner ear lighter).
    void ear(double cx, double wiggle) {
      canvas.save();
      canvas.translate(cx, 34);
      canvas.rotate(wiggle);
      final earPath = Path()
        ..moveTo(0, 12)
        ..quadraticBezierTo(-9, -12, 0, -16)
        ..quadraticBezierTo(9, -12, 0, 12);
      canvas.drawPath(earPath, earPaint);
      canvas.drawPath(earPath, outline);
      final inner = Path()
        ..moveTo(0, 6)
        ..quadraticBezierTo(-4, -7, 0, -10)
        ..quadraticBezierTo(4, -7, 0, 6);
      canvas.drawPath(inner, Paint()..color = Palette.blush);
      canvas.restore();
    }

    final earWiggle =
        math.sin(t * 2 * math.pi / 2.6) * 0.06 * motion;
    ear(34, -0.24 + earWiggle);
    ear(66, 0.24 - earWiggle);

    // Body: one soft blob (head and tummy together), softly lit.
    final bodyRect = Rect.fromCenter(
        center: const Offset(50, 70), width: 64, height: 68);
    canvas.drawOval(bodyRect, bodyShaded);
    canvas.drawOval(bodyRect, outline);

    // Belly with a faint inner glow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 84), width: 36, height: 30),
      bellyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(46, 80), width: 18, height: 12),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Arms.
    _paintArms(canvas, state, t, motion, pointDirection, bodyPaint, outline);

    // Face.
    _paintFace(canvas, state, t, motion);

    // Optional space helmet (Build the Rocket finale).
    if (wearsHelmet) {
      final helmet = Paint()
        ..color = Palette.babyBlue.withValues(alpha: 0.35);
      canvas.drawCircle(const Offset(50, 56), 30, helmet);
      canvas.drawCircle(
        const Offset(50, 56),
        30,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Sleepy Zs drift upward.
    if (state == MiloState.sleepy) {
      final zPaint = Paint()
        ..color = Palette.textSoft.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 2; i++) {
        final phase = (t / 2.4 + i * 0.5) % 1.0;
        final zx = 76.0 + i * 8;
        final zy = 40.0 - phase * 22;
        final zSize = 5.0 + i * 2;
        final zPath = Path()
          ..moveTo(zx - zSize / 2, zy - zSize / 2)
          ..lineTo(zx + zSize / 2, zy - zSize / 2)
          ..lineTo(zx - zSize / 2, zy + zSize / 2)
          ..lineTo(zx + zSize / 2, zy + zSize / 2);
        canvas.drawPath(
          zPath,
          zPaint
            ..color =
                Palette.textSoft.withValues(alpha: 0.7 * (1 - phase)),
        );
      }
    }

    canvas.restore();
  }

  static void _paintArms(
    Canvas canvas,
    MiloState state,
    double t,
    double motion,
    int pointDirection,
    Paint bodyPaint,
    Paint outline,
  ) {
    void arm(Offset shoulder, double angle, {double length = 20}) {
      canvas.save();
      canvas.translate(shoulder.dx, shoulder.dy);
      canvas.rotate(angle);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -5, length, 10),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, bodyPaint);
      canvas.drawRRect(rect, outline);
      canvas.restore();
    }

    const leftShoulder = Offset(22, 72);
    const rightShoulder = Offset(78, 72);
    final wave = math.sin(t * 2 * math.pi / 0.7) * 0.5 * motion;

    switch (state) {
      case MiloState.idle:
      case MiloState.sleepy:
        arm(leftShoulder, math.pi * 0.75);
        arm(rightShoulder, math.pi * 0.25);
      case MiloState.talking:
        arm(leftShoulder, math.pi * 0.75);
        arm(rightShoulder, -math.pi * 0.25 + wave * 0.3);
      case MiloState.pointing:
        if (pointDirection >= 0) {
          arm(leftShoulder, math.pi * 0.75);
          arm(rightShoulder, -0.15 + wave * 0.1, length: 26);
        } else {
          arm(rightShoulder, math.pi * 0.25);
          arm(leftShoulder, math.pi + 0.15 - wave * 0.1, length: 26);
        }
      case MiloState.happy:
      case MiloState.surprised:
        arm(leftShoulder, math.pi + math.pi * 0.3 - wave * 0.2);
        arm(rightShoulder, -math.pi * 0.3 + wave * 0.2);
      case MiloState.laughing:
        arm(leftShoulder, math.pi + math.pi * 0.4 - wave * 0.3);
        arm(rightShoulder, -math.pi * 0.4 + wave * 0.3);
      case MiloState.dancing:
        final beat = math.sin(t * 2 * math.pi / 0.55) * 0.6 * motion;
        arm(leftShoulder, math.pi + math.pi * 0.35 - beat);
        arm(rightShoulder, -math.pi * 0.35 + beat);
    }
  }

  static void _paintFace(
      Canvas canvas, MiloState state, double t, double motion) {
    final eyePaint = Paint()..color = Palette.outlineStrong;
    final eyeStroke = Paint()
      ..color = Palette.outlineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    const leftEye = Offset(40, 60);
    const rightEye = Offset(60, 60);

    // Blink every ~3.4 s.
    final blinkPhase = (t % 3.4) / 3.4;
    final blinking = blinkPhase > 0.96;

    final closedEyes = state == MiloState.sleepy ||
        state == MiloState.laughing ||
        blinking;
    final happyArcs = state == MiloState.happy || state == MiloState.dancing;

    if (closedEyes) {
      // Gentle closed arcs.
      for (final c in [leftEye, rightEye]) {
        canvas.drawArc(
          Rect.fromCenter(center: c, width: 11, height: 8),
          state == MiloState.laughing || happyArcs ? math.pi : 0,
          math.pi,
          false,
          eyeStroke,
        );
      }
    } else if (happyArcs) {
      // ^ ^ shaped happy eyes.
      for (final c in [leftEye, rightEye]) {
        canvas.drawArc(
          Rect.fromCenter(center: c, width: 11, height: 9),
          math.pi,
          math.pi,
          false,
          eyeStroke,
        );
      }
    } else {
      final size = state == MiloState.surprised ? 6.8 : 5.6;
      // Warm brown iris behind the dark pupil reads friendlier than
      // plain black dots.
      final iris = Paint()..color = const Color(0xFF6B4F3A);
      canvas.drawCircle(leftEye, size, iris);
      canvas.drawCircle(rightEye, size, iris);
      canvas.drawCircle(leftEye, size * 0.62, eyePaint);
      canvas.drawCircle(rightEye, size * 0.62, eyePaint);
      final highlight = Paint()..color = Colors.white.withValues(alpha: 0.95);
      final softLight = Paint()..color = Colors.white.withValues(alpha: 0.5);
      canvas.drawCircle(leftEye.translate(-1.8, -1.8), 1.9, highlight);
      canvas.drawCircle(rightEye.translate(-1.8, -1.8), 1.9, highlight);
      canvas.drawCircle(leftEye.translate(1.4, 1.6), 0.9, softLight);
      canvas.drawCircle(rightEye.translate(1.4, 1.6), 0.9, softLight);
    }

    // Cheeks: blurred blush reads softer than hard circles.
    final cheek = Paint()
      ..color = Palette.miloCheek.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    canvas.drawCircle(const Offset(32, 70), 5.0, cheek);
    canvas.drawCircle(const Offset(68, 70), 5.0, cheek);

    // Mouth.
    const mouthCenter = Offset(50, 74);
    final mouthStroke = Paint()
      ..color = Palette.outlineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    switch (state) {
      case MiloState.talking:
        final open =
            (math.sin(t * 2 * math.pi / 0.32).abs()) * 5 * motion + 2;
        canvas.drawOval(
          Rect.fromCenter(center: mouthCenter, width: 10, height: open + 3),
          Paint()..color = Palette.outlineStrong.withValues(alpha: 0.85),
        );
      case MiloState.laughing:
        final mouth = Path()
          ..moveTo(mouthCenter.dx - 8, mouthCenter.dy - 1)
          ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + 10,
              mouthCenter.dx + 8, mouthCenter.dy - 1)
          ..close();
        canvas.drawPath(
            mouth, Paint()..color = Palette.outlineStrong);
      case MiloState.surprised:
        canvas.drawOval(
          Rect.fromCenter(center: mouthCenter, width: 7, height: 9),
          Paint()..color = Palette.outlineStrong.withValues(alpha: 0.85),
        );
      case MiloState.sleepy:
        canvas.drawArc(
          Rect.fromCenter(
              center: mouthCenter.translate(0, 1), width: 8, height: 5),
          0,
          math.pi,
          false,
          mouthStroke,
        );
      default:
        canvas.drawArc(
          Rect.fromCenter(center: mouthCenter, width: 14, height: 9),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          mouthStroke,
        );
    }
  }
}
