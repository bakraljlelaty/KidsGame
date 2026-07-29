import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/theme/palette.dart';

/// The rocket parts used by Build the Rocket, listed bottom-to-top.
enum RocketPart {
  base('rocket_base', 1),
  body('rocket_body', 2),
  window('rocket_window', 4),
  nose('rocket_nose', 3);

  const RocketPart(this.id, this.layer);

  /// DraggableItem.itemId / DropZone.zoneId for this part.
  final String id;

  /// Paint order once assembled (the porthole overlays the body).
  final int layer;

  /// Which parts a stage uses (StageConfig.puzzlePieceCount), bottom to top.
  static List<RocketPart> forCount(int count) {
    if (count <= 2) return const [RocketPart.body, RocketPart.nose];
    if (count == 3) {
      return const [RocketPart.base, RocketPart.body, RocketPart.nose];
    }
    return const [
      RocketPart.base,
      RocketPart.body,
      RocketPart.window,
      RocketPart.nose,
    ];
  }
}

/// Procedural placeholder art for the rocket parts. All original soft-shape
/// drawings using only Palette colours; swapped for sprites later without
/// touching game logic.
class RocketArt {
  RocketArt._();

  static final Paint _outline = Paint()
    ..color = Palette.outlineStrong.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  // ------------------------------------------------------------- shapes

  static Path _nosePath(double w, double h) => Path()
    ..moveTo(w * 0.10, h * 0.98)
    ..quadraticBezierTo(w * 0.16, h * 0.34, w * 0.42, h * 0.10)
    ..quadraticBezierTo(w * 0.50, h * 0.02, w * 0.58, h * 0.10)
    ..quadraticBezierTo(w * 0.84, h * 0.34, w * 0.90, h * 0.98)
    ..close();

  static RRect _bodyRRect(double w, double h) => RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.01, w * 0.90, h * 0.98),
        Radius.circular(w * 0.16),
      );

  static Path _leftFin(double w, double h) => Path()
    ..moveTo(w * 0.32, h * 0.04)
    ..quadraticBezierTo(w * 0.10, h * 0.24, w * 0.04, h * 0.78)
    ..quadraticBezierTo(w * 0.18, h * 0.62, w * 0.34, h * 0.58)
    ..close();

  static Path _rightFin(double w, double h) => Path()
    ..moveTo(w * 0.68, h * 0.04)
    ..quadraticBezierTo(w * 0.90, h * 0.24, w * 0.96, h * 0.78)
    ..quadraticBezierTo(w * 0.82, h * 0.62, w * 0.66, h * 0.58)
    ..close();

  static Path _boosterPath(double w, double h) => Path()
    ..moveTo(w * 0.28, 0)
    ..lineTo(w * 0.72, 0)
    ..lineTo(w * 0.78, h * 0.62)
    ..lineTo(w * 0.22, h * 0.62)
    ..close();

  static Path _nozzlePath(double w, double h) => Path()
    ..moveTo(w * 0.40, h * 0.60)
    ..lineTo(w * 0.60, h * 0.60)
    ..lineTo(w * 0.66, h * 0.92)
    ..lineTo(w * 0.34, h * 0.92)
    ..close();

  /// The full outline of a part as one path (used by the silhouette).
  static Path partOutline(Vector2 size, RocketPart part) {
    final w = size.x;
    final h = size.y;
    switch (part) {
      case RocketPart.nose:
        return _nosePath(w, h);
      case RocketPart.body:
        return Path()..addRRect(_bodyRRect(w, h));
      case RocketPart.window:
        return Path()
          ..addOval(
              Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * 0.42));
      case RocketPart.base:
        return Path()
          ..addPath(_leftFin(w, h), Offset.zero)
          ..addPath(_rightFin(w, h), Offset.zero)
          ..addPath(_boosterPath(w, h), Offset.zero)
          ..addPath(_nozzlePath(w, h), Offset.zero);
    }
  }

  // ----------------------------------------------------------- painting

  /// Draws a full-colour part in a box of [size].
  static void paintPart(Canvas canvas, Vector2 size, RocketPart part) {
    final w = size.x;
    final h = size.y;
    switch (part) {
      case RocketPart.nose:
        _paintNose(canvas, w, h);
      case RocketPart.body:
        _paintBody(canvas, w, h);
      case RocketPart.window:
        _paintWindow(canvas, w, h);
      case RocketPart.base:
        _paintBase(canvas, w, h);
    }
  }

  /// Draws the dark translucent "where it goes" silhouette of a part.
  static void paintSilhouette(Canvas canvas, Vector2 size, RocketPart part) {
    final path = partOutline(size, part);
    canvas.drawPath(
        path, Paint()..color = Palette.skyNight.withValues(alpha: 0.30));
    canvas.drawPath(
      path,
      Paint()
        ..color = Palette.skyNight.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static void _paintNose(Canvas canvas, double w, double h) {
    final path = _nosePath(w, h);
    canvas.drawPath(path, Paint()..color = Palette.coral);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
      Paint()..color = Palette.cream.withValues(alpha: 0.85),
    );
    canvas.restore();
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.26), w * 0.06, Paint()..color = Palette.butter);
    canvas.drawPath(path, _outline);
  }

  static void _paintBody(Canvas canvas, double w, double h) {
    final rrect = _bodyRRect(w, h);
    canvas.drawRRect(rrect, Paint()..color = Palette.babyBlue);
    // Lower panel: this is where the little lights glow after assembly.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.16, h * 0.64, w * 0.68, h * 0.24),
          Radius.circular(w * 0.10)),
      Paint()..color = Palette.cream.withValues(alpha: 0.9),
    );
    final rivet = Paint()..color = Palette.outline.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(w * 0.20, h * 0.10), w * 0.028, rivet);
    canvas.drawCircle(Offset(w * 0.80, h * 0.10), w * 0.028, rivet);
    canvas.drawRRect(rrect, _outline);
  }

  static void _paintWindow(Canvas canvas, double w, double h) {
    final c = Offset(w / 2, h / 2);
    canvas.drawCircle(c, w * 0.42, Paint()..color = Palette.softPurple);
    canvas.drawCircle(c, w * 0.30, Paint()..color = Palette.skyNight);
    // Curved glass shine.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: w * 0.21),
      -2.4,
      1.2,
      false,
      Paint()
        ..color = Palette.cream.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round,
    );
    // A tiny star twinkling behind the glass.
    canvas.drawCircle(Offset(w * 0.58, h * 0.58), w * 0.035,
        Paint()..color = Palette.starGold);
    // Rim bolts.
    final bolt = Paint()..color = Palette.lavender;
    for (var i = 0; i < 4; i++) {
      final angle = math.pi / 4 + i * math.pi / 2;
      canvas.drawCircle(
        c + Offset(math.cos(angle), math.sin(angle)) * w * 0.36,
        w * 0.032,
        bolt,
      );
    }
    canvas.drawCircle(c, w * 0.42, _outline);
  }

  static void _paintBase(Canvas canvas, double w, double h) {
    // Fins behind the booster block.
    final fin = Paint()..color = Palette.softOrange;
    canvas.drawPath(_leftFin(w, h), fin);
    canvas.drawPath(_rightFin(w, h), fin);
    canvas.drawPath(_leftFin(w, h), _outline);
    canvas.drawPath(_rightFin(w, h), _outline);

    final booster = _boosterPath(w, h);
    canvas.drawPath(booster, Paint()..color = Palette.peach);
    canvas.drawPath(booster, _outline);

    final nozzle = _nozzlePath(w, h);
    canvas.drawPath(nozzle, Paint()..color = Palette.textSoft);
    canvas.drawPath(nozzle, _outline);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.92), width: w * 0.34, height: h * 0.10),
      Paint()..color = Palette.outlineStrong.withValues(alpha: 0.55),
    );
  }
}

/// Procedural backdrop for the cosy space workshop: soft lavender wall, a
/// rounded window with a few gentle stars, a small shelf of toys, the
/// workbench and the parts tray. Pure decoration, zero interaction.
class WorkshopArt {
  WorkshopArt._();

  static void paintWorkshop(
    Canvas canvas,
    Vector2 size, {
    required Rect trayRect,
    required double assemblyCx,
  }) {
    final w = size.x;
    final h = size.y;

    // Wall: warm lavender with a soft evening wash near the ceiling.
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = Palette.lavender);
    canvas.drawOval(
      Rect.fromLTWH(-w * 0.2, -h * 0.55, w * 1.4, h * 0.95),
      Paint()
        ..color = Palette.skyEvening.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    // A gentle pool of light over the assembly spot.
    canvas.drawCircle(
      Offset(assemblyCx, h * 0.40),
      w * 0.16,
      Paint()
        ..color = Palette.cream.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
    );

    _windowToSpace(canvas, w, h);
    _shelf(canvas, w, h);
    _workbench(canvas, w, h);

    // Parts tray.
    final tray = RRect.fromRectAndRadius(trayRect, const Radius.circular(18));
    canvas.drawRRect(
        tray, Paint()..color = Palette.peach.withValues(alpha: 0.55));
    canvas.drawRRect(
      tray,
      Paint()
        ..color = Palette.softBrown.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  static void _windowToSpace(Canvas canvas, double w, double h) {
    final rect = Rect.fromCenter(
        center: Offset(w * 0.76, h * 0.32), width: w * 0.28, height: h * 0.42);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.05));
    canvas.drawRRect(rrect.inflate(7), Paint()..color = Palette.cream);
    canvas.drawRRect(rrect, Paint()..color = Palette.skyEvening);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawOval(
      Rect.fromLTWH(rect.left - rect.width * 0.25,
          rect.top + rect.height * 0.40, rect.width * 1.5, rect.height),
      Paint()..color = Palette.skyNight.withValues(alpha: 0.5),
    );
    _star(
        canvas,
        Offset(rect.left + rect.width * 0.30, rect.top + rect.height * 0.26),
        rect.width * 0.035);
    _star(
        canvas,
        Offset(rect.left + rect.width * 0.70, rect.top + rect.height * 0.44),
        rect.width * 0.026);
    _star(
        canvas,
        Offset(rect.left + rect.width * 0.46, rect.top + rect.height * 0.70),
        rect.width * 0.022);
    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Palette.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
  }

  static void _star(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 2.4,
      Paint()
        ..color = Palette.starGold.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
        c, r, Paint()..color = Palette.starGold.withValues(alpha: 0.95));
    final ray = Paint()
      ..color = Palette.cream.withValues(alpha: 0.85)
      ..strokeWidth = r * 0.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c - Offset(0, r * 2.0), c + Offset(0, r * 2.0), ray);
    canvas.drawLine(c - Offset(r * 2.0, 0), c + Offset(r * 2.0, 0), ray);
  }

  static void _shelf(Canvas canvas, double w, double h) {
    final shelfY = h * 0.23;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.05, shelfY, w * 0.19, h * 0.022),
          const Radius.circular(6)),
      Paint()..color = Palette.softBrown.withValues(alpha: 0.8),
    );
    // Little jar.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.068, shelfY - h * 0.075, w * 0.034, h * 0.075),
          const Radius.circular(6)),
      Paint()..color = Palette.mint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.064, shelfY - h * 0.090, w * 0.042, h * 0.020),
          const Radius.circular(4)),
      Paint()..color = Palette.cream,
    );
    // Bouncy ball.
    canvas.drawCircle(Offset(w * 0.148, shelfY - h * 0.030), h * 0.030,
        Paint()..color = Palette.coral);
    canvas.drawCircle(Offset(w * 0.143, shelfY - h * 0.038), h * 0.008,
        Paint()..color = Palette.cream.withValues(alpha: 0.8));
    // Soft block.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.185, shelfY - h * 0.055, h * 0.055, h * 0.055),
          const Radius.circular(8)),
      Paint()..color = Palette.butter,
    );
    canvas.drawCircle(
        Offset(w * 0.185 + h * 0.0275, shelfY - h * 0.0275), h * 0.014,
        Paint()..color = Palette.softGreen);
  }

  static void _workbench(Canvas canvas, double w, double h) {
    // Legs first so the bench top covers their tops.
    final leg = Paint()..color = Palette.softBrown.withValues(alpha: 0.85);
    for (final x in [w * 0.10, w * 0.86]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, h * 0.72, w * 0.03, h * 0.12),
            const Radius.circular(8)),
        leg,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.02, h * 0.695, w * 0.96, h * 0.045),
          const Radius.circular(10)),
      Paint()..color = Palette.softBrown,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.02, h * 0.725, w * 0.96, h * 0.015),
          const Radius.circular(8)),
      Paint()..color = Palette.outline.withValues(alpha: 0.35),
    );
  }
}
