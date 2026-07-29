import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/theme/palette.dart';

/// Which farm friends appear in Feed the Animals.
enum AnimalKind {
  rabbit('carrot'),
  cow('grass'),
  monkey('banana');

  const AnimalKind(this.foodId);

  /// The DraggableItem.itemId this animal eats.
  final String foodId;
}

/// Procedural placeholder art for the farm animals and their food.
/// All original soft-shape drawings; swapped for sprites via ASSET_GUIDE.md.
class AnimalArt {
  AnimalArt._();

  static final Paint _outline = Paint()
    ..color = Palette.outlineStrong.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  /// Draws an animal in a box of [size]. [mouthOpen] 0..1 animates eating;
  /// [bounce] is a small vertical offset for idle/happy motion.
  static void paintAnimal(
    Canvas canvas,
    Vector2 size,
    AnimalKind kind, {
    double mouthOpen = 0,
    double bounce = 0,
  }) {
    canvas.save();
    canvas.translate(0, bounce);
    final w = size.x;
    final h = size.y;
    switch (kind) {
      case AnimalKind.rabbit:
        _rabbit(canvas, w, h, mouthOpen);
      case AnimalKind.cow:
        _cow(canvas, w, h, mouthOpen);
      case AnimalKind.monkey:
        _monkey(canvas, w, h, mouthOpen);
    }
    canvas.restore();
  }

  static void _face(Canvas canvas, double cx, double cy, double scale,
      double mouthOpen) {
    final eye = Paint()..color = Palette.outlineStrong;
    canvas.drawCircle(Offset(cx - 14 * scale, cy), 4 * scale, eye);
    canvas.drawCircle(Offset(cx + 14 * scale, cy), 4 * scale, eye);
    final cheek = Paint()..color = Palette.miloCheek.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(cx - 22 * scale, cy + 8 * scale), 5 * scale, cheek);
    canvas.drawCircle(Offset(cx + 22 * scale, cy + 8 * scale), 5 * scale, cheek);
    if (mouthOpen > 0.05) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + 13 * scale),
          width: 12 * scale,
          height: (4 + 12 * mouthOpen) * scale,
        ),
        Paint()..color = Palette.outlineStrong.withValues(alpha: 0.8),
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy + 10 * scale),
            width: 16 * scale,
            height: 10 * scale),
        math.pi * 0.15,
        math.pi * 0.7,
        false,
        _outline,
      );
    }
  }

  static void _rabbit(Canvas canvas, double w, double h, double mouthOpen) {
    final cx = w / 2;
    final body = Paint()..color = const Color(0xFFF3EEE5);
    // Ears.
    for (final side in [-1, 1]) {
      final ex = cx + side * w * 0.13;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ex, h * 0.2), width: w * 0.14, height: h * 0.36),
          body);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ex, h * 0.22), width: w * 0.06, height: h * 0.24),
          Paint()..color = Palette.blush);
    }
    // Body.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.62), width: w * 0.62, height: h * 0.55),
        body);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.62), width: w * 0.62, height: h * 0.55),
        _outline);
    // Belly.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.72), width: w * 0.3, height: h * 0.22),
        Paint()..color = const Color(0xFFFFFDF8));
    _face(canvas, cx, h * 0.55, w / 170, mouthOpen);
  }

  static void _cow(Canvas canvas, double w, double h, double mouthOpen) {
    final cx = w / 2;
    final body = Paint()..color = const Color(0xFFF7F3EA);
    // Ears.
    for (final side in [-1, 1]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + side * w * 0.3, h * 0.34),
              width: w * 0.16,
              height: h * 0.1),
          Paint()..color = Palette.softBrown);
    }
    // Horns.
    for (final side in [-1, 1]) {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx + side * w * 0.18, h * 0.22),
            width: w * 0.12,
            height: h * 0.12),
        side < 0 ? math.pi * 0.9 : math.pi * 1.6,
        math.pi * 0.5,
        false,
        _outline,
      );
    }
    // Body.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.6), width: w * 0.72, height: h * 0.58),
        body);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.6), width: w * 0.72, height: h * 0.58),
        _outline);
    // Patches.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - w * 0.2, h * 0.48),
            width: w * 0.16,
            height: h * 0.12),
        Paint()..color = Palette.softBrown.withValues(alpha: 0.7));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + w * 0.22, h * 0.72),
            width: w * 0.14,
            height: h * 0.1),
        Paint()..color = Palette.softBrown.withValues(alpha: 0.7));
    // Muzzle.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.68), width: w * 0.3, height: h * 0.16),
        Paint()..color = Palette.blush);
    _face(canvas, cx, h * 0.5, w / 170, mouthOpen);
  }

  static void _monkey(Canvas canvas, double w, double h, double mouthOpen) {
    final cx = w / 2;
    final fur = Paint()..color = Palette.softBrown;
    // Ears.
    for (final side in [-1, 1]) {
      canvas.drawCircle(
          Offset(cx + side * w * 0.28, h * 0.42), w * 0.1, fur);
      canvas.drawCircle(Offset(cx + side * w * 0.28, h * 0.42), w * 0.05,
          Paint()..color = Palette.peach);
    }
    // Body.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.6), width: w * 0.62, height: h * 0.56),
        fur);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.6), width: w * 0.62, height: h * 0.56),
        _outline);
    // Face patch.
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.58), width: w * 0.42, height: h * 0.36),
        Paint()..color = Palette.peach);
    _face(canvas, cx, h * 0.54, w / 170, mouthOpen);
  }

  /// Draws a food item in a box of [size].
  static void paintFood(Canvas canvas, Vector2 size, String foodId) {
    final w = size.x;
    final h = size.y;
    switch (foodId) {
      case 'carrot':
        final body = Path()
          ..moveTo(w * 0.34, h * 0.3)
          ..quadraticBezierTo(w * 0.24, h * 0.75, w * 0.5, h * 0.88)
          ..quadraticBezierTo(w * 0.74, h * 0.72, w * 0.64, h * 0.3)
          ..close();
        canvas.drawPath(body, Paint()..color = Palette.softOrange);
        canvas.drawPath(body, _outline);
        final leaves = Paint()
          ..color = Palette.softGreen
          ..strokeWidth = w * 0.06
          ..strokeCap = StrokeCap.round;
        for (final dx in [0.38, 0.5, 0.62]) {
          canvas.drawLine(Offset(w * dx, h * 0.28),
              Offset(w * (dx - 0.04), h * 0.08), leaves);
        }
      case 'grass':
        final grass = Paint()
          ..color = Palette.softGreen
          ..strokeWidth = w * 0.09
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 5; i++) {
          final x = w * (0.22 + i * 0.14);
          canvas.drawLine(
            Offset(x, h * 0.85),
            Offset(x + w * 0.05 * math.sin(i.toDouble()), h * 0.25),
            grass,
          );
        }
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(w / 2, h * 0.85),
                width: w * 0.8,
                height: h * 0.18),
            Paint()..color = Palette.meadow);
      case 'banana':
        final banana = Path()
          ..moveTo(w * 0.22, h * 0.32)
          ..quadraticBezierTo(w * 0.3, h * 0.78, w * 0.78, h * 0.6)
          ..quadraticBezierTo(w * 0.74, h * 0.72, w * 0.5, h * 0.82)
          ..quadraticBezierTo(w * 0.18, h * 0.68, w * 0.14, h * 0.36)
          ..close();
        canvas.drawPath(banana, Paint()..color = Palette.softYellow);
        canvas.drawPath(banana, _outline);
    }
  }
}
