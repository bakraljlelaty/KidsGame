import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../content/items/content_item.dart';
import '../../core/theme/palette.dart';
import 'game_images.dart';

/// Draws every ContentItem procedurally (original placeholder art). One
/// switch on artId keeps all item drawing swappable for sprites later.
///
/// All painters draw into a 100x100 design box scaled to [size].
class ItemArt {
  ItemArt._();

  static final Map<String, TextPainter> _glyphCache = {};

  static void paint(
    Canvas canvas,
    Size size,
    ContentItem item, {
    bool highContrast = false,
  }) {
    // Illustrated art takes over when the generated/commissioned image
    // exists; everything below stays as the universal fallback.
    final image = GameImages.item(item.artId);
    if (image != null) {
      GameImages.drawContain(image, canvas, size);
      return;
    }

    canvas.save();
    final scale = math.min(size.width / 100, size.height / 100);
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);

    final stroke = Paint()
      ..color = highContrast
          ? Palette.outlineStrong
          : Palette.outlineStrong.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 3.2 : 2.4
      ..strokeCap = StrokeCap.round;
    final color = item.color ?? Palette.coral;

    switch (item.artId) {
      case 'blob':
        _blob(canvas, color, stroke);
      case 'glyph':
        _glyphTile(canvas, item.glyph ?? '?', color, stroke);
      case 'shape_circle':
        canvas.drawCircle(const Offset(50, 50), 34, Paint()..color = color);
        canvas.drawCircle(const Offset(50, 50), 34, stroke);
      case 'shape_square':
        final r = RRect.fromRectAndRadius(
            Rect.fromCircle(center: const Offset(50, 50), radius: 32),
            const Radius.circular(10));
        canvas.drawRRect(r, Paint()..color = color);
        canvas.drawRRect(r, stroke);
      case 'shape_triangle':
        final p = Path()
          ..moveTo(50, 18)
          ..lineTo(84, 78)
          ..lineTo(16, 78)
          ..close();
        canvas.drawPath(p, Paint()..color = color);
        canvas.drawPath(p, stroke);
      case 'shape_star':
        final p = _starPath(const Offset(50, 52), 36);
        canvas.drawPath(p, Paint()..color = color);
        canvas.drawPath(p, stroke);
      case 'shape_heart':
        final p = Path()
          ..moveTo(50, 82)
          ..cubicTo(14, 54, 22, 20, 50, 38)
          ..cubicTo(78, 20, 86, 54, 50, 82)
          ..close();
        canvas.drawPath(p, Paint()..color = color);
        canvas.drawPath(p, stroke);
      case 'shape_rectangle':
        final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(50, 50), width: 74, height: 46),
            const Radius.circular(10));
        canvas.drawRRect(r, Paint()..color = color);
        canvas.drawRRect(r, stroke);
      case 'shape_oval':
        final rect =
            Rect.fromCenter(center: const Offset(50, 50), width: 74, height: 50);
        canvas.drawOval(rect, Paint()..color = color);
        canvas.drawOval(rect, stroke);
      case 'shape_diamond':
        final p = Path()
          ..moveTo(50, 14)
          ..lineTo(82, 50)
          ..lineTo(50, 86)
          ..lineTo(18, 50)
          ..close();
        canvas.drawPath(p, Paint()..color = color);
        canvas.drawPath(p, stroke);

      // ---- Animals (friendly simple faces/bodies) ----
      case 'animal_rabbit':
        _rabbit(canvas, stroke);
      case 'animal_cow':
        _cow(canvas, stroke);
      case 'animal_monkey':
        _monkey(canvas, stroke);
      case 'animal_duck':
        _duck(canvas, stroke);
      case 'animal_fish':
        _fish(canvas, stroke);
      case 'animal_cat':
        _cat(canvas, stroke);
      case 'animal_dog':
        _dog(canvas, stroke);
      case 'animal_bee':
        _bee(canvas, stroke);
      case 'animal_butterfly':
        _butterfly(canvas, stroke);
      case 'animal_ladybug':
        _ladybug(canvas, stroke);

      // ---- Food ----
      case 'food_apple':
        canvas.drawCircle(const Offset(50, 56), 28, Paint()..color = Palette.softRed);
        canvas.drawCircle(const Offset(50, 56), 28, stroke);
        canvas.drawLine(const Offset(50, 28), const Offset(50, 20), stroke..strokeWidth = 4);
        canvas.drawOval(Rect.fromCenter(center: const Offset(60, 24), width: 16, height: 9),
            Paint()..color = Palette.softGreen);
      case 'food_banana':
        final p = Path()
          ..moveTo(24, 34)
          ..quadraticBezierTo(32, 76, 76, 62)
          ..quadraticBezierTo(72, 72, 52, 80)
          ..quadraticBezierTo(20, 70, 18, 38)
          ..close();
        canvas.drawPath(p, Paint()..color = Palette.softYellow);
        canvas.drawPath(p, stroke);
      case 'food_strawberry':
        final p = Path()
          ..moveTo(50, 84)
          ..quadraticBezierTo(20, 60, 30, 38)
          ..quadraticBezierTo(50, 26, 70, 38)
          ..quadraticBezierTo(80, 60, 50, 84)
          ..close();
        canvas.drawPath(p, Paint()..color = Palette.softRed);
        canvas.drawPath(p, stroke);
        for (final o in const [Offset(42, 50), Offset(58, 50), Offset(50, 64)]) {
          canvas.drawCircle(o, 2, Paint()..color = Palette.butter);
        }
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 32), width: 26, height: 10),
            Paint()..color = Palette.softGreen);
      case 'food_orange':
        canvas.drawCircle(const Offset(50, 54), 28, Paint()..color = Palette.softOrange);
        canvas.drawCircle(const Offset(50, 54), 28, stroke);
        canvas.drawCircle(const Offset(58, 44), 4, Paint()..color = Palette.butter.withValues(alpha: 0.7));
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 26), width: 14, height: 8),
            Paint()..color = Palette.softGreen);
      case 'food_pear':
        final p = Path()
          ..moveTo(50, 22)
          ..quadraticBezierTo(60, 38, 66, 54)
          ..quadraticBezierTo(72, 78, 50, 82)
          ..quadraticBezierTo(28, 78, 34, 54)
          ..quadraticBezierTo(40, 38, 50, 22)
          ..close();
        canvas.drawPath(p, Paint()..color = Palette.softGreen);
        canvas.drawPath(p, stroke);
      case 'food_grapes':
        for (final o in const [
          Offset(38, 42), Offset(62, 42), Offset(50, 46),
          Offset(38, 60), Offset(62, 60), Offset(50, 64), Offset(50, 78),
        ]) {
          canvas.drawCircle(o, 11, Paint()..color = Palette.softPurple);
        }
        canvas.drawLine(const Offset(50, 34), const Offset(50, 24), stroke..strokeWidth = 4);
      case 'food_bread':
        final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(50, 56), width: 62, height: 38),
            const Radius.circular(16));
        canvas.drawRRect(r, Paint()..color = Palette.softBrown);
        canvas.drawRRect(r, stroke);
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 42), width: 62, height: 26),
            Paint()..color = Palette.peach);
      case 'food_milk':
        final p = Path()
          ..moveTo(36, 34)
          ..lineTo(64, 34)
          ..lineTo(68, 46)
          ..lineTo(68, 80)
          ..lineTo(32, 80)
          ..lineTo(32, 46)
          ..close();
        canvas.drawPath(p, Paint()..color = const Color(0xFFF7F5F0));
        canvas.drawPath(p, stroke);
        canvas.drawRect(Rect.fromLTWH(36, 26, 28, 8), Paint()..color = Palette.babyBlue);
      case 'food_cheese':
        final p = Path()
          ..moveTo(20, 66)
          ..lineTo(80, 66)
          ..lineTo(72, 40)
          ..lineTo(28, 40)
          ..close();
        canvas.drawPath(p, Paint()..color = Palette.softYellow);
        canvas.drawPath(p, stroke);
        canvas.drawCircle(const Offset(44, 56), 5, Paint()..color = Palette.butter);
        canvas.drawCircle(const Offset(62, 52), 4, Paint()..color = Palette.butter);
      case 'food_egg':
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 54), width: 44, height: 56),
            Paint()..color = const Color(0xFFF7F1E1));
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 54), width: 44, height: 56), stroke);
      case 'food_carrot':
        final p = Path()
          ..moveTo(38, 34)
          ..quadraticBezierTo(30, 70, 50, 82)
          ..quadraticBezierTo(70, 70, 62, 34)
          ..close();
        canvas.drawPath(p, Paint()..color = Palette.softOrange);
        canvas.drawPath(p, stroke);
        for (final dx in [40.0, 50.0, 60.0]) {
          canvas.drawLine(Offset(dx, 32), Offset(dx - 4, 16),
              Paint()..color = Palette.softGreen..strokeWidth = 5..strokeCap = StrokeCap.round);
        }
      case 'food_cookie':
        canvas.drawCircle(const Offset(50, 54), 27, Paint()..color = Palette.softBrown);
        canvas.drawCircle(const Offset(50, 54), 27, stroke);
        for (final o in const [Offset(42, 46), Offset(60, 50), Offset(48, 64), Offset(62, 64)]) {
          canvas.drawCircle(o, 3.4, Paint()..color = Palette.outlineStrong.withValues(alpha: 0.6));
        }

      // ---- Vehicles ----
      case 'vehicle_car':
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(18, 46, 64, 22), const Radius.circular(10)),
            Paint()..color = Palette.softRed);
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(32, 32, 36, 20), const Radius.circular(9)),
            Paint()..color = Palette.babyBlue);
        canvas.drawCircle(const Offset(34, 70), 8, Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(66, 70), 8, Paint()..color = Palette.outlineStrong);
      case 'vehicle_bus':
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(16, 32, 68, 36), const Radius.circular(10)),
            Paint()..color = Palette.softYellow);
        for (final dx in [26.0, 44.0, 62.0]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(dx, 38, 12, 12), const Radius.circular(4)),
              Paint()..color = Palette.babyBlue);
        }
        canvas.drawCircle(const Offset(32, 72), 7, Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(68, 72), 7, Paint()..color = Palette.outlineStrong);
      case 'vehicle_boat':
        final hull = Path()
          ..moveTo(20, 58)
          ..lineTo(80, 58)
          ..lineTo(68, 74)
          ..lineTo(32, 74)
          ..close();
        canvas.drawPath(hull, Paint()..color = Palette.softRed);
        final sail = Path()
          ..moveTo(52, 22)
          ..lineTo(52, 54)
          ..lineTo(28, 54)
          ..close();
        canvas.drawPath(sail, Paint()..color = const Color(0xFFF7F5F0));
        canvas.drawPath(sail, stroke);
      case 'vehicle_rocket':
        final body = Path()
          ..moveTo(50, 16)
          ..quadraticBezierTo(66, 40, 60, 70)
          ..lineTo(40, 70)
          ..quadraticBezierTo(34, 40, 50, 16)
          ..close();
        canvas.drawPath(body, Paint()..color = Palette.babyBlue);
        canvas.drawPath(body, stroke);
        canvas.drawCircle(const Offset(50, 44), 8, Paint()..color = const Color(0xFFFFFFFF));
        final flame = Path()
          ..moveTo(42, 72)
          ..quadraticBezierTo(50, 88, 58, 72)
          ..close();
        canvas.drawPath(flame, Paint()..color = Palette.softOrange);

      // ---- Toys ----
      case 'toy_ball':
        canvas.drawCircle(const Offset(50, 52), 28, Paint()..color = Palette.softBlue);
        canvas.drawArc(Rect.fromCircle(center: const Offset(50, 52), radius: 28),
            -0.6, 1.9, false, Paint()..color = Palette.softRed..style = PaintingStyle.stroke..strokeWidth = 12);
        canvas.drawCircle(const Offset(50, 52), 28, stroke);
      case 'toy_block':
        final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(50, 54), width: 52, height: 52),
            const Radius.circular(10));
        canvas.drawRRect(r, Paint()..color = Palette.softGreen);
        canvas.drawRRect(r, stroke);
        _glyphInto(canvas, 'A', const Offset(50, 54), 30, const Color(0xFFFFFFFF));
      case 'toy_teddy':
        canvas.drawCircle(const Offset(36, 34), 9, Paint()..color = Palette.softBrown);
        canvas.drawCircle(const Offset(64, 34), 9, Paint()..color = Palette.softBrown);
        canvas.drawCircle(const Offset(50, 44), 17, Paint()..color = Palette.softBrown);
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 70), width: 36, height: 30),
            Paint()..color = Palette.softBrown);
        canvas.drawCircle(const Offset(44, 42), 2.4, Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(56, 42), 2.4, Paint()..color = Palette.outlineStrong);
      case 'toy_drum':
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(26, 42, 48, 30), const Radius.circular(8)),
            Paint()..color = Palette.softRed);
        canvas.drawOval(Rect.fromLTWH(26, 32, 48, 20), Paint()..color = Palette.peach);
        canvas.drawOval(Rect.fromLTWH(26, 32, 48, 20), stroke);
      case 'toy_train':
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(20, 40, 34, 26), const Radius.circular(6)),
            Paint()..color = Palette.softBlue);
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(56, 30, 22, 36), const Radius.circular(6)),
            Paint()..color = Palette.softRed);
        canvas.drawCircle(const Offset(32, 72), 7, Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(50, 72), 7, Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(67, 72), 7, Paint()..color = Palette.outlineStrong);

      default:
        _blob(canvas, color, stroke);
    }
    canvas.restore();
  }

  // ---------------------------------------------------------------- helpers

  static void _blob(Canvas canvas, Color color, Paint stroke) {
    final p = Path()
      ..moveTo(50, 16)
      ..cubicTo(78, 16, 88, 36, 84, 58)
      ..cubicTo(80, 80, 62, 88, 46, 84)
      ..cubicTo(22, 78, 12, 58, 20, 38)
      ..cubicTo(26, 22, 36, 16, 50, 16)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawPath(p, stroke);
    canvas.drawCircle(const Offset(38, 34), 7,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.45));
  }

  static void _glyphTile(Canvas canvas, String glyph, Color color, Paint stroke) {
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(50, 50), width: 72, height: 72),
        const Radius.circular(20));
    canvas.drawRRect(r, Paint()..color = color);
    canvas.drawRRect(r, stroke);
    _glyphInto(canvas, glyph, const Offset(50, 50), 44, const Color(0xFFFFFFFF));
  }

  static void _glyphInto(
      Canvas canvas, String glyph, Offset center, double fontSize, Color color) {
    final key = '$glyph-$fontSize-${color.toARGB32()}';
    final painter = _glyphCache.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    });
    painter.paint(
        canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  static Path _starPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(
          center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  // Small animal painters (soft, friendly, original).

  static void _face(Canvas canvas, Offset at, double s, Paint stroke) {
    canvas.drawCircle(at.translate(-8 * s, 0), 2.6 * s, Paint()..color = Palette.outlineStrong);
    canvas.drawCircle(at.translate(8 * s, 0), 2.6 * s, Paint()..color = Palette.outlineStrong);
    canvas.drawArc(
        Rect.fromCenter(center: at.translate(0, 7 * s), width: 12 * s, height: 8 * s),
        math.pi * 0.15, math.pi * 0.7, false, stroke);
  }

  static void _rabbit(Canvas canvas, Paint stroke) {
    final body = Paint()..color = const Color(0xFFF3EEE5);
    for (final dx in [-11.0, 11.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(50 + dx, 26), width: 13, height: 30), body);
      canvas.drawOval(Rect.fromCenter(center: Offset(50 + dx, 28), width: 6, height: 20),
          Paint()..color = Palette.blush);
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 58), width: 52, height: 46), body);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 58), width: 52, height: 46), stroke);
    _face(canvas, const Offset(50, 54), 1, stroke);
  }

  static void _cow(Canvas canvas, Paint stroke) {
    final body = Paint()..color = const Color(0xFFF7F3EA);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 54), width: 58, height: 48), body);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 54), width: 58, height: 48), stroke);
    canvas.drawOval(Rect.fromCenter(center: const Offset(34, 42), width: 13, height: 9),
        Paint()..color = Palette.softBrown.withValues(alpha: 0.7));
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 66), width: 22, height: 13),
        Paint()..color = Palette.blush);
    for (final dx in [-24.0, 24.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(50 + dx, 34), width: 13, height: 8),
          Paint()..color = Palette.softBrown);
    }
    _face(canvas, const Offset(50, 48), 1, stroke);
  }

  static void _monkey(Canvas canvas, Paint stroke) {
    final fur = Paint()..color = Palette.softBrown;
    for (final dx in [-24.0, 24.0]) {
      canvas.drawCircle(Offset(50 + dx, 46), 9, fur);
      canvas.drawCircle(Offset(50 + dx, 46), 4.4, Paint()..color = Palette.peach);
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 54), width: 50, height: 46), fur);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 54), width: 50, height: 46), stroke);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 56), width: 34, height: 30),
        Paint()..color = Palette.peach);
    _face(canvas, const Offset(50, 52), 1, stroke);
  }

  static void _duck(Canvas canvas, Paint stroke) {
    canvas.drawOval(Rect.fromCenter(center: const Offset(46, 62), width: 46, height: 32),
        Paint()..color = Palette.softYellow);
    canvas.drawCircle(const Offset(62, 42), 14, Paint()..color = Palette.softYellow);
    canvas.drawCircle(const Offset(62, 42), 14, stroke);
    canvas.drawCircle(const Offset(66, 40), 2.6, Paint()..color = Palette.outlineStrong);
    final beak = Path()
      ..moveTo(74, 42)
      ..lineTo(86, 46)
      ..lineTo(74, 50)
      ..close();
    canvas.drawPath(beak, Paint()..color = Palette.softOrange);
  }

  static void _fish(Canvas canvas, Paint stroke) {
    canvas.drawOval(Rect.fromCenter(center: const Offset(46, 52), width: 46, height: 30),
        Paint()..color = Palette.coral);
    final tail = Path()
      ..moveTo(66, 52)
      ..lineTo(84, 40)
      ..lineTo(84, 64)
      ..close();
    canvas.drawPath(tail, Paint()..color = Palette.coral);
    canvas.drawPath(tail, stroke);
    canvas.drawCircle(const Offset(36, 48), 3, Paint()..color = Palette.outlineStrong);
  }

  static void _cat(Canvas canvas, Paint stroke) {
    final fur = Paint()..color = Palette.peach;
    for (final dx in [-18.0, 18.0]) {
      final ear = Path()
        ..moveTo(50 + dx - 8, 36)
        ..lineTo(50 + dx, 16)
        ..lineTo(50 + dx + 8, 36)
        ..close();
      canvas.drawPath(ear, fur);
      canvas.drawPath(ear, stroke);
    }
    canvas.drawCircle(const Offset(50, 54), 27, fur);
    canvas.drawCircle(const Offset(50, 54), 27, stroke);
    _face(canvas, const Offset(50, 52), 1, stroke);
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(Offset(50 + side * 24, 56), Offset(50 + side * 38, 52), stroke);
      canvas.drawLine(Offset(50 + side * 24, 62), Offset(50 + side * 38, 62), stroke);
    }
  }

  static void _dog(Canvas canvas, Paint stroke) {
    final fur = Paint()..color = Palette.softBrown;
    for (final dx in [-22.0, 22.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(50 + dx, 42), width: 15, height: 28), fur);
    }
    canvas.drawCircle(const Offset(50, 54), 27, Paint()..color = Palette.peach);
    canvas.drawCircle(const Offset(50, 54), 27, stroke);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 62), width: 16, height: 12),
        Paint()..color = const Color(0xFFF7F3EA));
    canvas.drawCircle(const Offset(50, 60), 4, Paint()..color = Palette.outlineStrong);
    _face(canvas, const Offset(50, 48), 1, stroke);
  }

  static void _bee(Canvas canvas, Paint stroke) {
    for (final dx in [-10.0, 10.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(50 + dx, 32), width: 22, height: 16),
          Paint()..color = Palette.babyBlue.withValues(alpha: 0.6));
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 56), width: 46, height: 34),
        Paint()..color = Palette.softYellow);
    for (final dx in [-8.0, 6.0]) {
      canvas.drawRect(Rect.fromLTWH(50 + dx - 3, 40, 7, 32),
          Paint()..color = Palette.outlineStrong.withValues(alpha: 0.75));
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 56), width: 46, height: 34), stroke);
    canvas.drawCircle(const Offset(34, 52), 2.6, Paint()..color = Palette.outlineStrong);
  }

  static void _butterfly(Canvas canvas, Paint stroke) {
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(50 + side * 17, 40), width: 28, height: 26),
          Paint()..color = Palette.softPink);
      canvas.drawOval(Rect.fromCenter(center: Offset(50 + side * 15, 64), width: 22, height: 20),
          Paint()..color = Palette.lavender);
      canvas.drawOval(Rect.fromCenter(center: Offset(50 + side * 17, 40), width: 28, height: 26), stroke);
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 52), width: 10, height: 40),
        Paint()..color = Palette.outlineStrong.withValues(alpha: 0.8));
  }

  static void _ladybug(Canvas canvas, Paint stroke) {
    canvas.drawCircle(const Offset(50, 40), 12, Paint()..color = Palette.outlineStrong);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 58), width: 48, height: 40),
        Paint()..color = Palette.softRed);
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 58), width: 48, height: 40), stroke);
    canvas.drawLine(const Offset(50, 40), const Offset(50, 78), stroke);
    for (final o in const [Offset(38, 52), Offset(62, 52), Offset(42, 68), Offset(58, 68)]) {
      canvas.drawCircle(o, 4, Paint()..color = Palette.outlineStrong.withValues(alpha: 0.8));
    }
  }
}
