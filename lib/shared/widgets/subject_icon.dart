import 'package:flutter/material.dart';

import '../../content/items/content_item.dart';
import '../../core/theme/palette.dart';
import '../../shared/characters/milo_painter.dart';
import '../../shared/characters/milo_state.dart';
import '../items/item_art.dart';
import '../models/subject.dart';

/// Icon-first representation of a subject room (no reading required).
class SubjectIcon extends StatelessWidget {
  const SubjectIcon({
    super.key,
    required this.subject,
    this.size = 72,
    this.languageCode = 'en',
  });

  final Subject subject;
  final double size;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SubjectIconPainter(subject, languageCode),
      ),
    );
  }
}

class _SubjectIconPainter extends CustomPainter {
  _SubjectIconPainter(this.subject, this.languageCode);

  final Subject subject;
  final String languageCode;

  @override
  void paint(Canvas canvas, Size size) {
    switch (subject) {
      case Subject.colors:
        final third = size.width / 2.2;
        void blob(Offset at, Color color) {
          canvas.save();
          canvas.translate(at.dx, at.dy);
          ItemArt.paint(canvas, Size.square(third * 1.4),
              ContentItem(id: 'b', artId: 'blob', color: color));
          canvas.restore();
        }

        blob(Offset(size.width * 0.02, size.height * 0.08), Palette.softRed);
        blob(Offset(size.width * 0.34, size.height * 0.0), Palette.softBlue);
        blob(Offset(size.width * 0.18, size.height * 0.36), Palette.softYellow);
      case Subject.shapes:
        canvas.save();
        canvas.translate(size.width * 0.02, size.height * 0.06);
        ItemArt.paint(canvas, Size.square(size.width * 0.6),
            const ContentItem(id: 's', artId: 'shape_star', color: Palette.starGold));
        canvas.restore();
        canvas.save();
        canvas.translate(size.width * 0.42, size.height * 0.4);
        ItemArt.paint(canvas, Size.square(size.width * 0.52),
            const ContentItem(id: 'c', artId: 'shape_circle', color: Palette.softBlue));
        canvas.restore();
      case Subject.animals:
        ItemArt.paint(canvas, size,
            const ContentItem(id: 'a', artId: 'animal_cat'));
      case Subject.food:
        ItemArt.paint(canvas, size,
            const ContentItem(id: 'f', artId: 'food_apple'));
      case Subject.numbers:
        ItemArt.paint(
            canvas,
            size,
            const ContentItem(
                id: 'n', artId: 'glyph', glyph: '123',
                color: Palette.softGreen));
      case Subject.letters:
        ItemArt.paint(
            canvas,
            size,
            ContentItem(
                id: 'l', artId: 'glyph',
                glyph: languageCode == 'ar' ? 'أ ب' : 'A B',
                color: Palette.softPurple));
      case Subject.art:
        // A painter's palette: three paint dots on a soft board.
        canvas.drawOval(
          Rect.fromLTWH(size.width * 0.08, size.height * 0.18,
              size.width * 0.84, size.height * 0.68),
          Paint()..color = Palette.peach,
        );
        canvas.drawOval(
          Rect.fromLTWH(size.width * 0.08, size.height * 0.18,
              size.width * 0.84, size.height * 0.68),
          Paint()
            ..color = Palette.outlineStrong.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        for (final (dx, dy, color) in [
          (0.3, 0.4, Palette.softRed),
          (0.55, 0.32, Palette.softBlue),
          (0.66, 0.58, Palette.softGreen),
        ]) {
          canvas.drawCircle(
            Offset(size.width * dx, size.height * dy),
            size.width * 0.1,
            Paint()..color = color,
          );
        }
      case Subject.milosWorld:
        MiloPainter.paint(canvas, size,
            state: MiloState.happy, time: 0.4, reducedMotion: true);
    }
  }

  @override
  bool shouldRepaint(_SubjectIconPainter oldDelegate) =>
      oldDelegate.subject != subject ||
      oldDelegate.languageCode != languageCode;
}
