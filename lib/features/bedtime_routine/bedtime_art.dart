import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/theme/palette.dart';

/// Procedural placeholder art for the Bedtime Routine mini-game.
///
/// All original soft-shape drawings using only [Palette] colours; swapped
/// for sprites later via ASSET_GUIDE.md without touching game logic.
class BedtimeArt {
  BedtimeArt._();

  static final Paint _outline = Paint()
    ..color = Palette.outlineStrong.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ---------------------------------------------------------------- Room

  /// The whole cosy evening bedroom backdrop: warm wall, floor, rug,
  /// dusk window, bed with pillow and the little nightstand.
  static void paintRoom(
    Canvas canvas,
    Vector2 size, {
    required Rect windowRect,
    required Rect bedRect,
    required Offset pillowCenter,
    required Rect standRect,
  }) {
    final w = size.x;
    final h = size.y;

    // Warm evening wall over the cream background.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.76),
      Paint()..color = Palette.peach.withValues(alpha: 0.42),
    );

    // Floor.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.74, w, h * 0.26),
      Paint()..color = Palette.softBrown.withValues(alpha: 0.28),
    );
    canvas.drawLine(
      Offset(0, h * 0.74),
      Offset(w, h * 0.74),
      Paint()
        ..color = Palette.outline.withValues(alpha: 0.35)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Round rug under the little pile of bedtime things.
    final rug = Rect.fromCenter(
      center: Offset(w * 0.40, h * 0.905),
      width: w * 0.46,
      height: h * 0.135,
    );
    canvas.drawOval(rug, Paint()..color = Palette.blush.withValues(alpha: 0.5));
    canvas.drawOval(
      Rect.fromCenter(
        center: rug.center,
        width: rug.width * 0.68,
        height: rug.height * 0.6,
      ),
      Paint()..color = Palette.cream.withValues(alpha: 0.55),
    );

    _window(canvas, windowRect);
    _bed(canvas, bedRect, pillowCenter);
    _nightstand(canvas, standRect);
  }

  static void _window(Canvas canvas, Rect rect) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.09));

    // Dusk sky.
    canvas.drawRRect(rr, Paint()..color = Palette.skyEvening);
    canvas.save();
    canvas.clipRRect(rr);
    // Last soft glow of the setting sun.
    canvas.drawCircle(
      Offset(rect.left + rect.width * 0.34, rect.bottom - rect.height * 0.06),
      rect.width * 0.30,
      Paint()
        ..color = Palette.butter.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    // Sleepy far-away hill.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom + rect.height * 0.10),
        width: rect.width * 1.4,
        height: rect.height * 0.44,
      ),
      Paint()..color = Palette.softPurple.withValues(alpha: 0.45),
    );
    canvas.restore();

    // Cross bars.
    final bar = Paint()
      ..color = Palette.cream.withValues(alpha: 0.85)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rect.center.dx, rect.top + 4),
      Offset(rect.center.dx, rect.bottom - 4),
      bar,
    );
    canvas.drawLine(
      Offset(rect.left + 4, rect.center.dy),
      Offset(rect.right - 4, rect.center.dy),
      bar,
    );

    // Frame.
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Palette.softBrown.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );

    // Curtains and rod.
    final curtain = Paint()..color = Palette.blush.withValues(alpha: 0.9);
    for (final left in [true, false]) {
      final r = Rect.fromLTWH(
        left
            ? rect.left - rect.width * 0.05
            : rect.right - rect.width * 0.12,
        rect.top - rect.height * 0.04,
        rect.width * 0.17,
        rect.height * 0.8,
      );
      final crr = RRect.fromRectAndRadius(r, Radius.circular(rect.width * 0.06));
      canvas.drawRRect(crr, curtain);
      canvas.drawRRect(crr, _outline);
    }
    canvas.drawLine(
      Offset(rect.left - rect.width * 0.08, rect.top - rect.height * 0.05),
      Offset(rect.right + rect.width * 0.08, rect.top - rect.height * 0.05),
      Paint()
        ..color = Palette.softBrown
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _bed(Canvas canvas, Rect bed, Offset pillowCenter) {
    // Headboard behind the pillow end.
    final headboard = Rect.fromLTWH(
      bed.right - bed.width * 0.13,
      bed.top - bed.height * 0.42,
      bed.width * 0.13,
      bed.height * 1.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headboard, Radius.circular(bed.width * 0.05)),
      Paint()..color = Palette.softBrown.withValues(alpha: 0.8),
    );

    // Legs.
    final leg = Paint()..color = Palette.softBrown;
    for (final x in [bed.left + bed.width * 0.03, bed.right - bed.width * 0.065]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, bed.bottom - 4, bed.width * 0.035, bed.height * 0.16),
          const Radius.circular(4),
        ),
        leg,
      );
    }

    // Mattress.
    final base = RRect.fromRectAndRadius(bed, Radius.circular(bed.height * 0.16));
    canvas.drawRRect(base, Paint()..color = Palette.miloBelly);
    canvas.drawRRect(base, _outline);

    // Cosy blanket over the foot end.
    final blanketRect = Rect.fromLTWH(
      bed.left,
      bed.top + bed.height * 0.30,
      bed.width * 0.66,
      bed.height * 0.70,
    );
    final blanket =
        RRect.fromRectAndRadius(blanketRect, Radius.circular(bed.height * 0.14));
    canvas.drawRRect(blanket, Paint()..color = Palette.lavender);
    canvas.drawRRect(blanket, _outline);
    final fold = Paint()
      ..color = Palette.babyBlue.withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final t in [0.30, 0.55]) {
      canvas.drawLine(
        Offset(blanketRect.left + blanketRect.width * t, blanketRect.top + 6),
        Offset(
          blanketRect.left + blanketRect.width * (t - 0.06),
          blanketRect.bottom - 6,
        ),
        fold,
      );
    }

    // Pillow.
    final pillowRect = Rect.fromCenter(
      center: pillowCenter,
      width: bed.width * 0.30,
      height: bed.height * 0.34,
    );
    canvas.drawOval(pillowRect, Paint()..color = Palette.cream);
    canvas.drawOval(pillowRect, _outline);
  }

  static void _nightstand(Canvas canvas, Rect r) {
    final body = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.12));
    canvas.drawRRect(body, Paint()..color = Palette.peach);
    canvas.drawRRect(body, _outline);
    // Table top.
    final top = Rect.fromLTWH(
      r.left - r.width * 0.08,
      r.top - r.height * 0.06,
      r.width * 1.16,
      r.height * 0.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(top, Radius.circular(r.width * 0.08)),
      Paint()..color = Palette.softBrown.withValues(alpha: 0.8),
    );
    // Drawer.
    canvas.drawLine(
      Offset(r.left + r.width * 0.12, r.center.dy),
      Offset(r.right - r.width * 0.12, r.center.dy),
      _outline,
    );
    canvas.drawCircle(
      Offset(r.center.dx, r.center.dy + r.height * 0.18),
      r.width * 0.07,
      Paint()..color = Palette.softBrown,
    );
  }

  // ------------------------------------------------------------- Objects

  /// The woven toy basket (drawn as the basket drop zone).
  static void paintBasket(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;
    final body = Path()
      ..moveTo(w * 0.10, h * 0.34)
      ..lineTo(w * 0.20, h * 0.92)
      ..quadraticBezierTo(w * 0.5, h * 1.0, w * 0.80, h * 0.92)
      ..lineTo(w * 0.90, h * 0.34)
      ..close();
    canvas.drawPath(body, Paint()..color = Palette.softBrown.withValues(alpha: 0.6));
    final weave = Paint()
      ..color = Palette.outline.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final t in [0.50, 0.66, 0.82]) {
      final p = Path()
        ..moveTo(w * 0.16, h * t)
        ..quadraticBezierTo(w * 0.5, h * (t + 0.06), w * 0.84, h * t);
      canvas.drawPath(p, weave);
    }
    canvas.drawPath(body, _outline);
    // Rim.
    final rim = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.24, w * 0.88, h * 0.16),
      Radius.circular(h * 0.08),
    );
    canvas.drawRRect(rim, Paint()..color = Palette.softBrown.withValues(alpha: 0.85));
    canvas.drawRRect(rim, _outline);
  }

  /// A soft two-tone toy ball.
  static void paintToy(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;
    final center = Offset(w * 0.5, h * 0.54);
    final radius = w * 0.36;
    final circle = Rect.fromCircle(center: center, radius: radius);
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawRect(circle, Paint()..color = Palette.softPurple);
    canvas.drawRect(
      Rect.fromLTWH(circle.left, center.dy - radius * 0.24, circle.width, radius * 0.48),
      Paint()..color = Palette.butter,
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.4),
      radius * 0.16,
      Paint()..color = Palette.cream.withValues(alpha: 0.8),
    );
    canvas.drawOval(circle, _outline);
  }

  /// A friendly upright toothbrush.
  static void paintToothbrush(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;
    // Handle.
    final handle = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.40, h * 0.26, w * 0.20, h * 0.66),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(handle, Paint()..color = Palette.softBlue);
    canvas.drawRRect(handle, _outline);
    // Brush head.
    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.37, h * 0.13, w * 0.26, h * 0.16),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(head, Paint()..color = Palette.babyBlue);
    canvas.drawRRect(head, _outline);
    // Bristles.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.37, h * 0.04, w * 0.26, h * 0.10),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = Palette.miloBelly,
    );
    final tuft = Paint()
      ..color = Palette.outline.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final t in [0.44, 0.50, 0.56]) {
      canvas.drawLine(Offset(w * t, h * 0.05), Offset(w * t, h * 0.13), tuft);
    }
  }

  /// A pyjama shirt with a sleepy moon and dots.
  static void paintPajamas(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;
    final shirt = Path()
      ..moveTo(w * 0.32, h * 0.14)
      ..lineTo(w * 0.68, h * 0.14)
      ..lineTo(w * 0.94, h * 0.40)
      ..lineTo(w * 0.80, h * 0.56)
      ..lineTo(w * 0.72, h * 0.46)
      ..lineTo(w * 0.72, h * 0.88)
      ..lineTo(w * 0.28, h * 0.88)
      ..lineTo(w * 0.28, h * 0.46)
      ..lineTo(w * 0.20, h * 0.56)
      ..lineTo(w * 0.06, h * 0.40)
      ..close();
    canvas.drawPath(shirt, Paint()..color = Palette.softPink);
    canvas.drawPath(shirt, _outline);
    // Collar.
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.16), width: w * 0.20, height: h * 0.14),
      0,
      math.pi,
      false,
      _outline,
    );
    // Sleepy crescent moon.
    final moonCenter = Offset(w * 0.5, h * 0.60);
    canvas.drawCircle(moonCenter, w * 0.10, Paint()..color = Palette.butter);
    canvas.drawCircle(
      Offset(moonCenter.dx + w * 0.045, moonCenter.dy - h * 0.02),
      w * 0.085,
      Paint()..color = Palette.softPink,
    );
    // Little star dots.
    for (final d in const [
      Offset(0.36, 0.42),
      Offset(0.64, 0.40),
      Offset(0.40, 0.76),
      Offset(0.62, 0.74),
    ]) {
      canvas.drawCircle(
        Offset(w * d.dx, h * d.dy),
        w * 0.028,
        Paint()..color = Palette.butter,
      );
    }
  }

  /// The soft teddy bear.
  static void paintTeddy(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;
    final fur = Paint()..color = Palette.softBrown;

    // Ears.
    for (final side in [-1, 1]) {
      canvas.drawCircle(Offset(cx + side * w * 0.15, h * 0.13), w * 0.095, fur);
      canvas.drawCircle(
        Offset(cx + side * w * 0.15, h * 0.13),
        w * 0.048,
        Paint()..color = Palette.peach,
      );
    }
    // Head.
    canvas.drawCircle(Offset(cx, h * 0.24), w * 0.21, fur);
    canvas.drawCircle(Offset(cx, h * 0.24), w * 0.21, _outline);
    // Arms.
    for (final side in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + side * w * 0.26, h * 0.55),
            width: w * 0.16,
            height: h * 0.24),
        fur,
      );
    }
    // Body.
    final bodyRect = Rect.fromCenter(
        center: Offset(cx, h * 0.62), width: w * 0.52, height: h * 0.48);
    canvas.drawOval(bodyRect, fur);
    canvas.drawOval(bodyRect, _outline);
    // Feet.
    for (final side in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + side * w * 0.14, h * 0.86),
            width: w * 0.17,
            height: h * 0.11),
        fur,
      );
    }
    // Belly.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h * 0.65), width: w * 0.28, height: h * 0.26),
      Paint()..color = Palette.miloBelly,
    );
    // Face.
    final eye = Paint()..color = Palette.outlineStrong;
    canvas.drawCircle(Offset(cx - w * 0.075, h * 0.22), w * 0.028, eye);
    canvas.drawCircle(Offset(cx + w * 0.075, h * 0.22), w * 0.028, eye);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h * 0.285), width: w * 0.14, height: h * 0.085),
      Paint()..color = Palette.miloBelly,
    );
    canvas.drawCircle(
      Offset(cx, h * 0.265),
      w * 0.025,
      Paint()..color = Palette.outlineStrong.withValues(alpha: 0.8),
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, h * 0.29), width: w * 0.08, height: h * 0.05),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      _outline,
    );
    final cheek = Paint()..color = Palette.miloCheek.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(cx - w * 0.14, h * 0.27), w * 0.035, cheek);
    canvas.drawCircle(Offset(cx + w * 0.14, h * 0.27), w * 0.035, cheek);
  }

  /// The little bedside lamp; [isOn] switches the warm glow off.
  static void paintLamp(Canvas canvas, Vector2 size,
      {required bool isOn, double time = 0}) {
    final w = size.x;
    final h = size.y;
    if (isOn) {
      // Slow breathing glow, never flashing.
      final breathe = 1 + 0.04 * math.sin(time * 1.4);
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.30),
        w * 0.52 * breathe,
        Paint()
          ..color = Palette.starGold.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    // Base.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.92), width: w * 0.52, height: h * 0.11),
      Paint()..color = Palette.softBrown,
    );
    // Stem.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.46, h * 0.44, w * 0.08, h * 0.48),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = Palette.softBrown.withValues(alpha: 0.9),
    );
    // Warm little bulb peeking under the shade.
    if (isOn) {
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.44),
        w * 0.09,
        Paint()..color = Palette.starGold.withValues(alpha: 0.85),
      );
    }
    // Shade.
    final shade = Path()
      ..moveTo(w * 0.26, h * 0.46)
      ..lineTo(w * 0.74, h * 0.46)
      ..lineTo(w * 0.63, h * 0.10)
      ..lineTo(w * 0.37, h * 0.10)
      ..close();
    canvas.drawPath(shade, Paint()..color = isOn ? Palette.butter : Palette.lavender);
    canvas.drawPath(shade, _outline);
  }

  /// A tiny four-point night star with a soft halo. [glow] 0..1 twinkles.
  static void paintStar(Canvas canvas, Vector2 size, {double glow = 1}) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2;
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = Palette.starGold.withValues(alpha: 0.22 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final star = Path()
      ..moveTo(cx, cy - r)
      ..quadraticBezierTo(cx + r * 0.16, cy - r * 0.16, cx + r, cy)
      ..quadraticBezierTo(cx + r * 0.16, cy + r * 0.16, cx, cy + r)
      ..quadraticBezierTo(cx - r * 0.16, cy + r * 0.16, cx - r, cy)
      ..quadraticBezierTo(cx - r * 0.16, cy - r * 0.16, cx, cy - r)
      ..close();
    canvas.drawPath(
      star,
      Paint()..color = Palette.starGold.withValues(alpha: math.min(1.0, 0.95 * glow)),
    );
  }
}
