import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../features/rewards/sticker_catalog.dart';

/// Draws every collectible sticker as simple original vector art.
/// Replace with real illustrations later by swapping this painter only.
class StickerArtView extends StatelessWidget {
  const StickerArtView({
    super.key,
    required this.art,
    this.size = 72,
    this.semanticLabel,
  });

  final StickerArt art;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final painting = CustomPaint(
      size: Size.square(size),
      painter: _StickerPainter(art),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: painting);
    return Semantics(label: semanticLabel, image: true, child: painting);
  }
}

class _StickerPainter extends CustomPainter {
  _StickerPainter(this.art);

  final StickerArt art;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    // Sticker backing: white circle with soft edge.
    canvas.drawCircle(
      const Offset(50, 50),
      48,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(50, 50),
      48,
      Paint()
        ..color = Palette.outline.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final stroke = Paint()
      ..color = Palette.outlineStrong.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    switch (art) {
      case StickerArt.carrot:
        final body = Path()
          ..moveTo(38, 40)
          ..quadraticBezierTo(30, 72, 48, 78)
          ..quadraticBezierTo(64, 72, 60, 42)
          ..close();
        canvas.drawPath(body, Paint()..color = Palette.softOrange);
        canvas.drawPath(body, stroke);
        for (final dx in [36.0, 46.0, 56.0]) {
          canvas.drawLine(Offset(dx, 28), Offset(dx + 6, 40),
              stroke..strokeWidth = 4);
          canvas.drawLine(Offset(dx, 28), Offset(dx + 6, 40),
              Paint()
                ..color = Palette.softGreen
                ..strokeWidth = 5
                ..strokeCap = StrokeCap.round);
        }
      case StickerArt.bunny:
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 62), width: 40, height: 34),
            Paint()..color = const Color(0xFFEFEBE4));
        for (final dx in [42.0, 58.0]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(dx, 34), width: 12, height: 30),
              Paint()..color = const Color(0xFFEFEBE4));
          canvas.drawOval(Rect.fromCenter(center: Offset(dx, 36), width: 5, height: 20),
              Paint()..color = Palette.blush);
        }
        canvas.drawCircle(const Offset(44, 58), 2.6, Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(56, 58), 2.6, Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(50, 65), 2.6, Paint()..color = Palette.miloCheek);
      case StickerArt.banana:
        final banana = Path()
          ..moveTo(30, 40)
          ..quadraticBezierTo(38, 74, 72, 62)
          ..quadraticBezierTo(70, 70, 52, 76)
          ..quadraticBezierTo(28, 70, 26, 44)
          ..close();
        canvas.drawPath(banana, Paint()..color = Palette.softYellow);
        canvas.drawPath(banana, stroke);
      case StickerArt.bubble:
        canvas.drawCircle(const Offset(50, 50), 26,
            Paint()..color = Palette.babyBlue.withValues(alpha: 0.7));
        canvas.drawCircle(const Offset(50, 50), 26, stroke);
        canvas.drawArc(Rect.fromCircle(center: const Offset(50, 50), radius: 18),
            math.pi * 1.1, math.pi * 0.5, false,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round);
      case StickerArt.fish:
        canvas.drawOval(Rect.fromCenter(center: const Offset(46, 52), width: 40, height: 26),
            Paint()..color = Palette.coral);
        final tail = Path()
          ..moveTo(64, 52)
          ..lineTo(78, 42)
          ..lineTo(78, 62)
          ..close();
        canvas.drawPath(tail, Paint()..color = Palette.coral);
        canvas.drawCircle(const Offset(38, 49), 3, Paint()..color = Palette.outlineStrong);
      case StickerArt.starfish:
        _drawStar(canvas, const Offset(50, 52), 26, Paint()..color = Palette.softPink);
        canvas.drawCircle(const Offset(46, 48), 2.4, Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(56, 48), 2.4, Paint()..color = Palette.outlineStrong);
      case StickerArt.sockRed:
        _drawSock(canvas, Palette.softRed, stroke);
      case StickerArt.sockStriped:
        _drawSock(canvas, Palette.softBlue, stroke);
        for (final dy in [36.0, 46.0]) {
          canvas.drawLine(Offset(38, dy), Offset(60, dy),
              Paint()
                ..color = Colors.white.withValues(alpha: 0.8)
                ..strokeWidth = 5);
        }
      case StickerArt.sockDotted:
        _drawSock(canvas, Palette.softGreen, stroke);
        for (final o in const [Offset(44, 38), Offset(54, 48), Offset(44, 56)]) {
          canvas.drawCircle(o, 3.4, Paint()..color = Colors.white.withValues(alpha: 0.85));
        }
      case StickerArt.soap:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: const Offset(50, 54), width: 44, height: 30),
                const Radius.circular(14)),
            Paint()..color = Palette.lavender);
        for (final o in const [Offset(38, 34), Offset(50, 28), Offset(62, 34)]) {
          canvas.drawCircle(o, 5, Paint()..color = Colors.white.withValues(alpha: 0.75));
        }
      case StickerArt.duck:
        canvas.drawOval(Rect.fromCenter(center: const Offset(48, 58), width: 40, height: 28),
            Paint()..color = Palette.softYellow);
        canvas.drawCircle(const Offset(62, 44), 12, Paint()..color = Palette.softYellow);
        canvas.drawCircle(const Offset(65, 42), 2.4, Paint()..color = Palette.outlineStrong);
        final beak = Path()
          ..moveTo(72, 44)
          ..lineTo(82, 47)
          ..lineTo(72, 50)
          ..close();
        canvas.drawPath(beak, Paint()..color = Palette.softOrange);
      case StickerArt.sponge:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: const Offset(50, 52), width: 46, height: 32),
                const Radius.circular(10)),
            Paint()..color = Palette.softYellow);
        for (final o in const [Offset(40, 46), Offset(54, 56), Offset(62, 44)]) {
          canvas.drawCircle(o, 3, Paint()..color = Palette.softOrange.withValues(alpha: 0.6));
        }
      case StickerArt.rocket:
        final body = Path()
          ..moveTo(50, 22)
          ..quadraticBezierTo(64, 40, 60, 66)
          ..lineTo(40, 66)
          ..quadraticBezierTo(36, 40, 50, 22)
          ..close();
        canvas.drawPath(body, Paint()..color = Palette.babyBlue);
        canvas.drawPath(body, stroke);
        canvas.drawCircle(const Offset(50, 46), 7, Paint()..color = Colors.white);
        final flame = Path()
          ..moveTo(44, 68)
          ..quadraticBezierTo(50, 82, 56, 68)
          ..close();
        canvas.drawPath(flame, Paint()..color = Palette.softOrange);
      case StickerArt.planet:
        canvas.drawCircle(const Offset(50, 50), 20, Paint()..color = Palette.softPurple);
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 52), width: 62, height: 14),
            Paint()
              ..color = Palette.softYellow.withValues(alpha: 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4);
      case StickerArt.star:
        _drawStar(canvas, const Offset(50, 52), 28, Paint()..color = Palette.starGold);
      case StickerArt.moon:
        final moon = Path()
          ..addArc(Rect.fromCircle(center: const Offset(50, 50), radius: 24), -math.pi / 2, math.pi)
          ..arcTo(Rect.fromCircle(center: const Offset(42, 50), radius: 20), math.pi / 2, -math.pi, false)
          ..close();
        canvas.drawPath(moon, Paint()..color = Palette.softYellow);
      case StickerArt.teddy:
        canvas.drawCircle(const Offset(38, 36), 9, Paint()..color = Palette.softBrown);
        canvas.drawCircle(const Offset(62, 36), 9, Paint()..color = Palette.softBrown);
        canvas.drawCircle(const Offset(50, 46), 16, Paint()..color = Palette.softBrown);
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 68), width: 34, height: 26),
            Paint()..color = Palette.softBrown);
        canvas.drawCircle(const Offset(45, 44), 2.2, Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(55, 44), 2.2, Paint()..color = Palette.outlineStrong);
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 50), width: 8, height: 6),
            Paint()..color = Palette.miloBelly);
      case StickerArt.lamp:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: const Offset(50, 40), width: 34, height: 22),
                const Radius.circular(8)),
            Paint()..color = Palette.softYellow);
        canvas.drawLine(const Offset(50, 51), const Offset(50, 70), stroke..strokeWidth = 4);
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 74), width: 26, height: 8),
            Paint()..color = Palette.softBrown);
    }
    canvas.restore();
  }

  void _drawSock(Canvas canvas, Color color, Paint stroke) {
    final sock = Path()
      ..moveTo(40, 26)
      ..lineTo(60, 26)
      ..lineTo(60, 52)
      ..quadraticBezierTo(74, 60, 66, 72)
      ..quadraticBezierTo(56, 80, 46, 70)
      ..lineTo(40, 52)
      ..close();
    canvas.drawPath(sock, Paint()..color = color);
    canvas.drawPath(sock, stroke);
    canvas.drawRect(Rect.fromLTWH(38, 24, 24, 8),
        Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StickerPainter oldDelegate) => oldDelegate.art != art;
}
