import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/theme/palette.dart';

/// Procedural placeholder art for the Muddy Pig Bath.
///
/// All original soft-shape drawings using only [Palette] colours; swapped
/// for sprites later without touching game logic.
class PigArt {
  PigArt._();

  static final Paint _outline = Paint()
    ..color = Palette.outlineStrong.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  /// Draws the big smiling pig in a box of [size]. [happy] switches the
  /// eyes to delighted closed arcs; [bounce] is a small vertical offset
  /// for the gentle idle breathing.
  static void paintPig(
    Canvas canvas,
    Vector2 size, {
    bool happy = false,
    double bounce = 0,
  }) {
    canvas.save();
    canvas.translate(0, bounce);
    final w = size.x;
    final h = size.y;
    final body = Paint()..color = Palette.softPink;
    final darker = Paint()..color = Palette.blush;

    // Curly tail peeking out on the left, behind the body.
    final tail = Paint()
      ..color = Palette.softPink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    final tailPath = Path()
      ..moveTo(w * 0.10, h * 0.52)
      ..cubicTo(w * 0.01, h * 0.44, w * 0.00, h * 0.60, w * 0.07, h * 0.57)
      ..cubicTo(w * 0.12, h * 0.55, w * 0.10, h * 0.48, w * 0.05, h * 0.50);
    canvas.drawPath(tailPath, tail);

    // Little legs (tops hidden by the body).
    for (final dx in [0.31, 0.44, 0.56, 0.69]) {
      final leg = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * (dx - 0.045), h * 0.72, w * 0.09, h * 0.22),
        Radius.circular(w * 0.045),
      );
      canvas.drawRRect(leg, darker);
      canvas.drawRRect(leg, _outline);
    }

    // Floppy ears (bases hidden by the body).
    for (final side in [-1, 1]) {
      final bx = w * 0.5 + side * w * 0.26;
      final ear = Path()
        ..moveTo(bx - side * w * 0.10, h * 0.245)
        ..quadraticBezierTo(
            bx + side * w * 0.02, h * 0.03, bx + side * w * 0.13, h * 0.12)
        ..quadraticBezierTo(
            bx + side * w * 0.13, h * 0.22, bx + side * w * 0.02, h * 0.26)
        ..close();
      canvas.drawPath(ear, body);
      canvas.drawPath(ear, _outline);
      final inner = Path()
        ..moveTo(bx - side * w * 0.03, h * 0.22)
        ..quadraticBezierTo(
            bx + side * w * 0.035, h * 0.09, bx + side * w * 0.09, h * 0.135)
        ..quadraticBezierTo(
            bx + side * w * 0.08, h * 0.20, bx, h * 0.23)
        ..close();
      canvas.drawPath(inner, Paint()..color = Palette.blush.withValues(alpha: 0.8));
    }

    // Round body.
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.84,
      height: h * 0.70,
    );
    canvas.drawOval(bodyRect, body);
    canvas.drawOval(bodyRect, _outline);

    // Soft belly highlight.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.70), width: w * 0.38, height: h * 0.22),
      Paint()..color = Palette.miloBelly.withValues(alpha: 0.3),
    );

    // Cheeks.
    final cheek = Paint()..color = Palette.miloCheek.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(w * 0.26, h * 0.56), w * 0.05, cheek);
    canvas.drawCircle(Offset(w * 0.74, h * 0.56), w * 0.05, cheek);

    // Eyes: friendly dots, or happy closed arcs after the bath.
    if (happy) {
      final happyEye = Paint()
        ..color = Palette.outlineStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round;
      for (final side in [-1, 1]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w * 0.5 + side * w * 0.13, h * 0.43),
            width: w * 0.09,
            height: h * 0.07,
          ),
          math.pi,
          math.pi,
          false,
          happyEye,
        );
      }
    } else {
      final eye = Paint()..color = Palette.outlineStrong;
      canvas.drawCircle(Offset(w * 0.37, h * 0.41), w * 0.028, eye);
      canvas.drawCircle(Offset(w * 0.63, h * 0.41), w * 0.028, eye);
    }

    // Snout with nostrils.
    final snoutRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.54),
      width: w * 0.25,
      height: h * 0.155,
    );
    canvas.drawOval(snoutRect, darker);
    canvas.drawOval(snoutRect, _outline);
    final nostril = Paint()
      ..color = Palette.outlineStrong.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(w * 0.455, h * 0.54), w * 0.016, nostril);
    canvas.drawCircle(Offset(w * 0.545, h * 0.54), w * 0.016, nostril);

    // Big content smile below the snout.
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.66), width: w * 0.20, height: h * 0.09),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      _outline,
    );

    canvas.restore();
  }

  /// Draws the water bucket in a box of [size].
  static void paintBucket(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;

    // Handle arching over the top.
    final handle = Paint()
      ..color = Palette.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.34), width: w * 0.60, height: h * 0.44),
      math.pi,
      math.pi,
      false,
      handle,
    );

    // Body with a softly rounded bottom.
    final body = Path()
      ..moveTo(w * 0.17, h * 0.34)
      ..lineTo(w * 0.83, h * 0.34)
      ..lineTo(w * 0.74, h * 0.86)
      ..quadraticBezierTo(w * 0.5, h * 0.94, w * 0.26, h * 0.86)
      ..close();
    canvas.drawPath(body, Paint()..color = Palette.softBlue);
    canvas.drawPath(body, _outline);

    // Rim filled with water.
    final rim = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.34), width: w * 0.66, height: h * 0.16);
    canvas.drawOval(rim, Paint()..color = Palette.babyBlue);
    canvas.drawOval(rim, _outline);

    // Water shine.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.42, h * 0.33), width: w * 0.18, height: h * 0.05),
      Paint()..color = Palette.cream.withValues(alpha: 0.7),
    );

    // Gentle highlight on the side.
    final shine = Paint()
      ..color = Palette.cream.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.30, h * 0.46), Offset(w * 0.33, h * 0.78), shine);
  }

  /// Draws the fluffy towel in a box of [size].
  static void paintTowel(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.08, h * 0.15, w * 0.92, h * 0.80),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(rrect, Paint()..color = Palette.butter);

    // Stripes and a soft fold, clipped to the towel.
    canvas.save();
    canvas.clipRRect(rrect);
    final stripe = Paint()..color = Palette.lavender.withValues(alpha: 0.65);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.28, w, h * 0.10), stripe);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.55, w, h * 0.10), stripe);
    final fold = Paint()
      ..color = Palette.cream.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.12), width: w * 0.7, height: h * 0.3),
      math.pi * 0.2,
      math.pi * 0.6,
      false,
      fold,
    );
    canvas.restore();
    canvas.drawRRect(rrect, _outline);

    // Fringe along the bottom edge.
    final fringe = Paint()
      ..color = Palette.softOrange
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    for (var x = w * 0.15; x <= w * 0.86; x += w * 0.09) {
      canvas.drawLine(Offset(x, h * 0.80), Offset(x, h * 0.92), fringe);
    }
  }

  /// Draws the towel wrapped snugly around the pig (a wide cosy band).
  static void paintTowelWrap(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.03, h * 0.08, w * 0.97, h * 0.92),
      Radius.circular(h * 0.42),
    );
    canvas.drawRRect(rrect, Paint()..color = Palette.butter);
    canvas.save();
    canvas.clipRRect(rrect);
    final stripe = Paint()..color = Palette.lavender.withValues(alpha: 0.65);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.30, w, h * 0.14), stripe);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.14), stripe);
    canvas.restore();
    canvas.drawRRect(rrect, _outline);

    // A tucked-in corner so it reads as wrapped, not floating.
    final tuck = Path()
      ..moveTo(w * 0.78, h * 0.14)
      ..quadraticBezierTo(w * 0.88, h * 0.30, w * 0.80, h * 0.50)
      ..quadraticBezierTo(w * 0.72, h * 0.34, w * 0.72, h * 0.18)
      ..close();
    canvas.drawPath(tuck, Paint()..color = Palette.cream.withValues(alpha: 0.8));
    canvas.drawPath(tuck, _outline);
  }

  /// Draws the little scrubbing sponge in a box of [size].
  static void paintSponge(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.06, h * 0.14, w * 0.94, h * 0.86),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(rrect, Paint()..color = Palette.softYellow);

    // Sponge holes.
    final hole = Paint()..color = Palette.softOrange.withValues(alpha: 0.45);
    canvas.drawCircle(Offset(w * 0.30, h * 0.40), w * 0.06, hole);
    canvas.drawCircle(Offset(w * 0.55, h * 0.62), w * 0.05, hole);
    canvas.drawCircle(Offset(w * 0.72, h * 0.35), w * 0.045, hole);
    canvas.drawCircle(Offset(w * 0.40, h * 0.72), w * 0.04, hole);
    canvas.drawRRect(rrect, _outline);

    // Tiny soap bubbles drifting off the top corner.
    final bubble = Paint()..color = Palette.babyBlue.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(w * 0.20, h * 0.10), w * 0.055, bubble);
    canvas.drawCircle(Offset(w * 0.32, h * 0.02), w * 0.04, bubble);
    canvas.drawCircle(Offset(w * 0.86, h * 0.10), w * 0.035, bubble);
  }
}
