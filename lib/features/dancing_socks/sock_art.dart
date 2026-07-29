import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/theme/palette.dart';

/// How a sock pair is decorated. Patterns keep pairs tellable-apart even
/// for children who perceive colour differently.
enum SockPattern { plain, stripes, dots }

/// The look of one sock pair: body colour, cuff colour and pattern.
class SockStyle {
  const SockStyle({
    required this.id,
    required this.body,
    required this.cuff,
    required this.pattern,
    required this.patternColor,
  });

  /// Shared by the pair: DraggableItem.itemId == DropZone.zoneId.
  final String id;

  final Color body;
  final Color cuff;
  final SockPattern pattern;
  final Color patternColor;
}

/// The original sock wardrobe (Palette colours only).
class SockStyles {
  SockStyles._();

  static const plainBlue = SockStyle(
    id: 'sock_plain_blue',
    body: Palette.softBlue,
    cuff: Palette.butter,
    pattern: SockPattern.plain,
    patternColor: Palette.butter,
  );

  static const dottyPink = SockStyle(
    id: 'sock_dots_pink',
    body: Palette.softPink,
    cuff: Palette.cream,
    pattern: SockPattern.dots,
    patternColor: Palette.cream,
  );

  static const stripyBlue = SockStyle(
    id: 'sock_stripes_blue',
    body: Palette.softBlue,
    cuff: Palette.butter,
    pattern: SockPattern.stripes,
    patternColor: Palette.butter,
  );

  static const dottyBlue = SockStyle(
    id: 'sock_dots_blue',
    body: Palette.softBlue,
    cuff: Palette.cream,
    pattern: SockPattern.dots,
    patternColor: Palette.cream,
  );
}

/// Procedural placeholder art for Dancing Socks: the socks themselves and
/// the cosy bedroom backdrop. All original soft-shape drawings.
class SockArt {
  SockArt._();

  static Paint _outline(bool highContrast) => Paint()
    ..color = highContrast
        ? Palette.outlineStrong
        : Palette.outline.withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = highContrast ? 3.5 : 2.5
    ..strokeCap = StrokeCap.round;

  /// Draws one sock in a box of [size]. The silhouette is a rounded L with
  /// the toe pointing left; [flip] mirrors it so a waiting sock and its
  /// arriving partner can face each other. When [alive], the sock gets a
  /// friendly little face (eyes + smile).
  static void paintSock(
    Canvas canvas,
    Vector2 size,
    SockStyle style, {
    bool alive = false,
    bool flip = false,
    bool highContrast = false,
  }) {
    final w = size.x;
    final h = size.y;
    canvas.save();
    if (flip) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    final path = _sockPath(w, h);
    canvas.drawPath(path, Paint()..color = style.body);
    _paintPattern(canvas, path, w, h, style);
    canvas.drawPath(path, _outline(highContrast));

    // Cosy cuff along the top.
    final cuff = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.345, h * 0.045, w * 0.53, h * 0.155),
      Radius.circular(h * 0.075),
    );
    canvas.drawRRect(cuff, Paint()..color = style.cuff);
    canvas.drawRRect(cuff, _outline(highContrast));

    if (alive) _paintFace(canvas, w, h);
    canvas.restore();
  }

  /// Rounded-L sock silhouette, toe pointing left, in a w x h box.
  static Path _sockPath(double w, double h) => Path()
    ..moveTo(w * 0.38, h * 0.14)
    ..lineTo(w * 0.83, h * 0.14)
    ..lineTo(w * 0.83, h * 0.68)
    ..quadraticBezierTo(w * 0.83, h * 0.92, w * 0.60, h * 0.93)
    ..lineTo(w * 0.34, h * 0.93)
    ..quadraticBezierTo(w * 0.12, h * 0.93, w * 0.12, h * 0.76)
    ..quadraticBezierTo(w * 0.12, h * 0.62, w * 0.28, h * 0.585)
    ..quadraticBezierTo(w * 0.38, h * 0.57, w * 0.38, h * 0.48)
    ..close();

  static void _paintPattern(
    Canvas canvas,
    Path sockPath,
    double w,
    double h,
    SockStyle style,
  ) {
    if (style.pattern == SockPattern.plain) return;
    canvas.save();
    canvas.clipPath(sockPath);
    switch (style.pattern) {
      case SockPattern.stripes:
        final stripe = Paint()
          ..color = style.patternColor
          ..strokeWidth = h * 0.055
          ..strokeCap = StrokeCap.round;
        for (var y = h * 0.30; y <= h * 0.95; y += h * 0.16) {
          canvas.drawLine(Offset(0, y), Offset(w, y), stripe);
        }
      case SockPattern.dots:
        final dot = Paint()..color = style.patternColor;
        var row = 0;
        for (var y = h * 0.30; y <= h * 0.95; y += h * 0.15) {
          final startX = row.isEven ? w * 0.16 : w * 0.235;
          for (var x = startX; x <= w * 0.92; x += w * 0.15) {
            canvas.drawCircle(Offset(x, y), w * 0.042, dot);
          }
          row++;
        }
      case SockPattern.plain:
        break;
    }
    canvas.restore();
  }

  /// Simple happy face on the sock leg (only once the pair is together).
  static void _paintFace(Canvas canvas, double w, double h) {
    // Soft patch so the face reads clearly over any pattern.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.605, h * 0.375),
        width: w * 0.40,
        height: h * 0.24,
      ),
      Paint()..color = Palette.cream.withValues(alpha: 0.75),
    );

    final eye = Paint()..color = Palette.outlineStrong;
    canvas.drawCircle(Offset(w * 0.51, h * 0.34), w * 0.035, eye);
    canvas.drawCircle(Offset(w * 0.70, h * 0.34), w * 0.035, eye);

    final cheek = Paint()..color = Palette.miloCheek.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(w * 0.455, h * 0.415), w * 0.038, cheek);
    canvas.drawCircle(Offset(w * 0.755, h * 0.415), w * 0.038, cheek);

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.605, h * 0.41),
        width: w * 0.16,
        height: h * 0.10,
      ),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = Palette.outlineStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Friendly bedroom backdrop: wallpaper dots, sunny window, rounded
  /// dresser (where the waiting socks sit) and a warm rug (where the loose
  /// socks landed). Pure decoration, zero interaction.
  static void paintBedroom(Canvas canvas, Vector2 size) {
    final w = size.x;
    final h = size.y;

    // Soft wallpaper dots on the upper wall.
    final wallDot = Paint()..color = Palette.cream.withValues(alpha: 0.5);
    for (var i = 0; i < 10; i++) {
      final x = w * (0.05 + 0.10 * i);
      final y = h * (0.10 + 0.14 * ((i * 3) % 4));
      canvas.drawCircle(Offset(x, y), 4 + w * 0.008, wallDot);
    }

    // Warm wooden floor.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
      Paint()..color = Palette.softBrown.withValues(alpha: 0.30),
    );
    canvas.drawLine(
      Offset(0, h * 0.78),
      Offset(w, h * 0.78),
      Paint()
        ..color = Palette.outline.withValues(alpha: 0.25)
        ..strokeWidth = 3,
    );

    // Window with a sunny sky.
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.565, h * 0.05, w * 0.25, h * 0.36),
      const Radius.circular(18),
    );
    canvas.drawRRect(frame, Paint()..color = Palette.cream);
    final glass = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.578, h * 0.085, w * 0.224, h * 0.29),
      const Radius.circular(12),
    );
    canvas.drawRRect(glass, Paint()..color = Palette.babyBlue);
    canvas.save();
    canvas.clipRRect(glass);
    canvas.drawCircle(
      Offset(w * 0.62, h * 0.15),
      w * 0.032,
      Paint()..color = Palette.butter,
    );
    final cloud = Paint()..color = Palette.cream.withValues(alpha: 0.9);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.745, h * 0.26),
        width: w * 0.09,
        height: h * 0.07,
      ),
      cloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.71, h * 0.29),
        width: w * 0.07,
        height: h * 0.06,
      ),
      cloud,
    );
    canvas.restore();
    final bars = Paint()
      ..color = Palette.cream
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.69, h * 0.085), Offset(w * 0.69, h * 0.375), bars);
    canvas.drawLine(Offset(w * 0.578, h * 0.23), Offset(w * 0.802, h * 0.23), bars);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.55, h * 0.41, w * 0.28, h * 0.035),
        const Radius.circular(8),
      ),
      Paint()..color = Palette.cream,
    );

    // Rounded dresser on the left.
    final dresser = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.13, h * 0.18, w * 0.30, h * 0.66),
      const Radius.circular(22),
    );
    canvas.drawRRect(dresser, Paint()..color = Palette.softBrown.withValues(alpha: 0.45));
    final drawerPaint = Paint()..color = Palette.cream.withValues(alpha: 0.5);
    final knob = Paint()..color = Palette.butter;
    for (var i = 0; i < 3; i++) {
      final top = h * (0.23 + 0.20 * i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.155, top, w * 0.25, h * 0.145),
          const Radius.circular(14),
        ),
        drawerPaint,
      );
      canvas.drawCircle(Offset(w * 0.28, top + h * 0.0725), 6, knob);
    }

    // Warm rug on the right.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.71, h * 0.82),
        width: w * 0.46,
        height: h * 0.17,
      ),
      Paint()..color = Palette.coral.withValues(alpha: 0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.71, h * 0.82),
        width: w * 0.36,
        height: h * 0.12,
      ),
      Paint()..color = Palette.butter.withValues(alpha: 0.55),
    );
  }
}
