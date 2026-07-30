import 'dart:ui';

import '../../core/theme/palette.dart';
import 'subject.dart';

/// One signature pastel per concept area, used by room doors, path unit
/// cards and progress rows so each subject is recognisable at a glance —
/// always paired with its icon, never color alone.
extension SubjectStyle on Subject {
  Color get accent => switch (this) {
        Subject.colors => Palette.coral,
        Subject.shapes => Palette.softBlue,
        Subject.animals => Palette.softGreen,
        Subject.food => Palette.softOrange,
        Subject.numbers => Palette.softPurple,
        Subject.letters => Palette.babyBlue,
        Subject.art => Palette.softPink,
        Subject.milosWorld => Palette.butter,
      };

  Color get accentSoft => Color.lerp(accent, const Color(0xFFFFFFFF), 0.55)!;
}
