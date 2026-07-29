import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../models/game_id.dart';

/// Simple original icon for each world tile on the map. All vector-drawn
/// placeholders; swap this painter when real artwork arrives.
class WorldIcon extends StatelessWidget {
  const WorldIcon({super.key, required this.gameId, this.size = 96});

  final GameId gameId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _WorldIconPainter(gameId),
      ),
    );
  }
}

class _WorldIconPainter extends CustomPainter {
  _WorldIconPainter(this.gameId);

  final GameId gameId;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final stroke = Paint()
      ..color = Palette.outlineStrong.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    switch (gameId) {
      case GameId.feedAnimals:
        // Little barn.
        canvas.drawRect(Rect.fromLTWH(26, 46, 48, 34),
            Paint()..color = Palette.softRed);
        final roof = Path()
          ..moveTo(20, 48)
          ..lineTo(50, 24)
          ..lineTo(80, 48)
          ..close();
        canvas.drawPath(roof, Paint()..color = Palette.softBrown);
        canvas.drawPath(roof, stroke);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(42, 58, 16, 22), const Radius.circular(8)),
            Paint()..color = Palette.miloBelly);
      case GameId.bubblePop:
        canvas.drawCircle(const Offset(38, 44), 18,
            Paint()..color = Palette.babyBlue.withValues(alpha: 0.75));
        canvas.drawCircle(const Offset(64, 60), 13,
            Paint()..color = Palette.mint.withValues(alpha: 0.75));
        canvas.drawCircle(const Offset(60, 30), 8,
            Paint()..color = Palette.blush.withValues(alpha: 0.75));
        canvas.drawCircle(const Offset(38, 44), 18, stroke);
      case GameId.dancingSocks:
        _sock(canvas, const Offset(38, 50), Palette.softRed, -0.15, stroke);
        _sock(canvas, const Offset(62, 52), Palette.softBlue, 0.15, stroke);
      case GameId.muddyPig:
        canvas.drawCircle(const Offset(50, 52), 26,
            Paint()..color = Palette.softPink);
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(50, 56), width: 16, height: 12),
            Paint()..color = Palette.miloCheek);
        canvas.drawCircle(const Offset(46, 56), 2.2,
            Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(54, 56), 2.2,
            Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(42, 44), 2.6,
            Paint()..color = Palette.outlineStrong);
        canvas.drawCircle(const Offset(58, 44), 2.6,
            Paint()..color = Palette.outlineStrong);
        // Mud splash.
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(36, 72), width: 18, height: 8),
            Paint()..color = Palette.softBrown.withValues(alpha: 0.7));
      case GameId.buildRocket:
        final body = Path()
          ..moveTo(50, 20)
          ..quadraticBezierTo(66, 42, 60, 70)
          ..lineTo(40, 70)
          ..quadraticBezierTo(34, 42, 50, 20)
          ..close();
        canvas.drawPath(body, Paint()..color = Palette.babyBlue);
        canvas.drawPath(body, stroke);
        canvas.drawCircle(const Offset(50, 46), 8, Paint()..color = Colors.white);
        final flame = Path()
          ..moveTo(42, 72)
          ..quadraticBezierTo(50, 86, 58, 72)
          ..close();
        canvas.drawPath(flame, Paint()..color = Palette.softOrange);
      case GameId.bedtimeRoutine:
        // Crescent moon and one star.
        final moon = Path()
          ..addArc(Rect.fromCircle(center: const Offset(46, 50), radius: 22),
              -math.pi / 2, math.pi)
          ..arcTo(Rect.fromCircle(center: const Offset(38, 50), radius: 18),
              math.pi / 2, -math.pi, false)
          ..close();
        canvas.drawPath(moon, Paint()..color = Palette.softYellow);
        _star(canvas, const Offset(68, 36), 8, Paint()..color = Palette.starGold);
        _star(canvas, const Offset(72, 62), 5, Paint()..color = Palette.starGold);
    }
    canvas.restore();
  }

  void _sock(Canvas canvas, Offset at, Color color, double rotation,
      Paint stroke) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(rotation);
    final sock = Path()
      ..moveTo(-8, -24)
      ..lineTo(8, -24)
      ..lineTo(8, 2)
      ..quadraticBezierTo(20, 8, 14, 18)
      ..quadraticBezierTo(4, 26, -4, 16)
      ..lineTo(-8, 2)
      ..close();
    canvas.drawPath(sock, Paint()..color = color);
    canvas.drawPath(sock, stroke);
    canvas.restore();
  }

  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(
          center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WorldIconPainter oldDelegate) =>
      oldDelegate.gameId != gameId;
}
