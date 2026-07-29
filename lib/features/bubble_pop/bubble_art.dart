import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/theme/palette.dart';

/// The bubble colours a round can ask for. Each maps onto one of the four
/// soft game-object colours and its matching voice instruction (mapped in
/// the game file so this art file stays audio-free).
enum BubbleHue {
  blue(Palette.softBlue),
  yellow(Palette.softYellow),
  red(Palette.softRed),
  green(Palette.softGreen);

  const BubbleHue(this.color);

  /// The colour of the circle drawn inside the bubble.
  final Color color;
}

/// Procedural placeholder art for Bubble Pop: the translucent bubbles, the
/// friendly little fish and the calm underwater backdrop. All original
/// soft-shape drawings using only Palette colours.
class BubbleArt {
  BubbleArt._();

  /// A translucent bubble with a coloured circle floating inside.
  /// [opacity] fades the whole bubble (used by the pop animation);
  /// [highContrast] switches the rim to the strong outline colour.
  static void paintBubble(
    Canvas canvas,
    Vector2 size,
    Color color, {
    double opacity = 1,
    bool highContrast = false,
  }) {
    final r = size.x / 2;
    final center = Offset(size.x / 2, size.y / 2);

    // Watery translucent shell.
    canvas.drawCircle(
      center,
      r,
      Paint()..color = Palette.babyBlue.withValues(alpha: 0.32 * opacity),
    );

    // The coloured circle inside.
    canvas.drawCircle(
      center,
      r * 0.52,
      Paint()..color = color.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      center,
      r * 0.52,
      Paint()
        ..color = Palette.outline.withValues(alpha: 0.35 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, r * 0.035),
    );

    // Bubble rim.
    canvas.drawCircle(
      center,
      r - math.max(1.5, r * 0.02),
      Paint()
        ..color = (highContrast ? Palette.outlineStrong : Palette.cream)
            .withValues(alpha: (highContrast ? 0.75 : 0.8) * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.5, r * 0.045),
    );

    // Glossy highlight, upper left.
    canvas.save();
    canvas.translate(center.dx - r * 0.42, center.dy - r * 0.45);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: r * 0.5,
        height: r * 0.22,
      ),
      Paint()..color = Palette.cream.withValues(alpha: 0.75 * opacity),
    );
    canvas.restore();

    // Tiny second shine, lower right.
    canvas.drawCircle(
      Offset(center.dx + r * 0.4, center.dy + r * 0.42),
      r * 0.08,
      Paint()..color = Palette.cream.withValues(alpha: 0.5 * opacity),
    );
  }

  /// A small friendly fish, drawn facing right in a box of [size].
  /// [tailWag] (-1..1) waves the tail; [smiling] widens the happy mouth.
  static void paintFish(
    Canvas canvas,
    Vector2 size,
    Color bodyColor, {
    double tailWag = 0,
    bool smiling = true,
  }) {
    final w = size.x;
    final h = size.y;
    final outline = Paint()
      ..color = Palette.outlineStrong.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, w * 0.028)
      ..strokeCap = StrokeCap.round;
    final body = Paint()..color = bodyColor;

    // Tail, waving gently.
    final wag = tailWag * h * 0.1;
    final tail = Path()
      ..moveTo(w * 0.3, h * 0.5)
      ..quadraticBezierTo(w * 0.1, h * 0.32 + wag, w * 0.04, h * 0.2 + wag)
      ..quadraticBezierTo(w * 0.14, h * 0.5, w * 0.04, h * 0.8 + wag)
      ..quadraticBezierTo(w * 0.1, h * 0.66 + wag, w * 0.3, h * 0.5)
      ..close();
    canvas.drawPath(tail, body);
    canvas.drawPath(tail, outline);

    // Body.
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.58, h * 0.52),
      width: w * 0.64,
      height: h * 0.68,
    );
    canvas.drawOval(bodyRect, body);
    canvas.drawOval(bodyRect, outline);

    // Top fin.
    final fin = Path()
      ..moveTo(w * 0.5, h * 0.22)
      ..quadraticBezierTo(w * 0.58, h * 0.0, w * 0.7, h * 0.22)
      ..close();
    canvas.drawPath(fin, body);
    canvas.drawPath(fin, outline);

    // Belly sheen.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.58, h * 0.66),
        width: w * 0.42,
        height: h * 0.24,
      ),
      Paint()..color = Palette.cream.withValues(alpha: 0.45),
    );

    // Eye with a glint.
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.44),
      h * 0.07,
      Paint()..color = Palette.outlineStrong,
    );
    canvas.drawCircle(
      Offset(w * 0.735, h * 0.42),
      h * 0.022,
      Paint()..color = Palette.cream,
    );

    // Rosy cheek.
    canvas.drawCircle(
      Offset(w * 0.66, h * 0.56),
      h * 0.055,
      Paint()..color = Palette.miloCheek.withValues(alpha: 0.55),
    );

    // Happy little mouth.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.84, h * 0.55),
        width: w * (smiling ? 0.1 : 0.07),
        height: h * (smiling ? 0.14 : 0.1),
      ),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      outline,
    );
  }

  /// Calm underwater backdrop: soft vertical gradient, gentle light rays,
  /// a sandy floor with rounded rocks and slowly swaying seaweed, plus a
  /// few tiny static bubble specks. [time] drives the (very slow) seaweed
  /// sway; pass a constant for reduced motion.
  static void paintUnderwater(Canvas canvas, Vector2 size, double time) {
    final w = size.x;
    final h = size.y;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Water: light near the surface, softly deeper below.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.underwater, Palette.skyEvening],
        ).createShader(rect),
    );

    // Gentle light rays fanning down from the surface (static, no shimmer).
    final ray = Paint()..color = Palette.cream.withValues(alpha: 0.1);
    for (final (dx, tilt, width) in [
      (0.22, 0.1, 0.06),
      (0.46, 0.02, 0.09),
      (0.72, -0.08, 0.05),
    ]) {
      final top = w * dx;
      final spread = w * width;
      final drift = h * tilt;
      final path = Path()
        ..moveTo(top - spread * 0.4, -10)
        ..lineTo(top + spread * 0.4, -10)
        ..lineTo(top + spread * 1.6 + drift, h)
        ..lineTo(top - spread * 1.6 + drift, h)
        ..close();
      canvas.drawPath(path, ray);
    }

    // Tiny static bubble specks drifting in the water column.
    final speck = Paint()..color = Palette.cream.withValues(alpha: 0.22);
    for (var i = 0; i < 9; i++) {
      final fx = 0.08 + (i * 0.37) % 0.86;
      final fy = 0.12 + (i * 0.53) % 0.62;
      canvas.drawCircle(
        Offset(w * fx, h * fy),
        2.0 + (i % 3),
        speck,
      );
    }

    // Sandy floor.
    canvas.drawOval(
      Rect.fromLTWH(-w * 0.15, h * 0.9, w * 1.3, h * 0.3),
      Paint()..color = Palette.peach.withValues(alpha: 0.9),
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.3, h * 0.94, w * 0.9, h * 0.24),
      Paint()..color = Palette.butter.withValues(alpha: 0.7),
    );

    // Rounded rocks.
    for (final (fx, fw, fh, color) in [
      (0.16, 0.11, 0.07, Palette.lavender),
      (0.62, 0.14, 0.09, Palette.blush),
      (0.86, 0.09, 0.06, Palette.lavender),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * fx, h * 0.95),
          width: w * fw,
          height: h * fh * 2,
        ),
        Paint()..color = color.withValues(alpha: 0.85),
      );
    }

    // Slowly swaying seaweed.
    for (final (fx, height, color, phase) in [
      (0.08, 0.2, Palette.softGreen, 0.0),
      (0.3, 0.14, Palette.mint, 1.7),
      (0.7, 0.17, Palette.mint, 3.1),
      (0.93, 0.22, Palette.softGreen, 4.4),
    ]) {
      final sway = math.sin(time * 2 * math.pi / 6 + phase) * w * 0.008;
      final baseX = w * fx;
      final baseY = h * 0.97;
      final tipY = baseY - h * height;
      final stalk = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(6, w * 0.012)
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(baseX, baseY)
        ..quadraticBezierTo(
          baseX - sway * 2,
          (baseY + tipY) / 2,
          baseX + sway * 3,
          tipY,
        );
      canvas.drawPath(path, stalk);
      final side = Path()
        ..moveTo(baseX, baseY - h * height * 0.4)
        ..quadraticBezierTo(
          baseX + w * 0.014 + sway,
          baseY - h * height * 0.55,
          baseX + w * 0.02 + sway * 2,
          baseY - h * height * 0.75,
        );
      canvas.drawPath(
        side,
        Paint()
          ..color = color.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(4, w * 0.008)
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
