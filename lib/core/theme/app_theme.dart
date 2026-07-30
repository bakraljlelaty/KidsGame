import 'package:flutter/material.dart';

import 'palette.dart';

/// Material theme for parent screens plus shared child-area styling.
///
/// Typography: "Baloo" (Baloo 2 SemiBold) with "BalooArabic"
/// (Baloo Bhaijaan 2) as the fallback for Arabic glyphs — one warm rounded
/// voice across both scripts. Body copy in the parent area stays on the
/// platform default font for long-text readability; headings, buttons,
/// tabs and all child-area labels use Baloo.
class AppTheme {
  AppTheme._();

  static const String displayFont = 'Baloo';
  static const List<String> displayFallback = ['BalooArabic'];

  /// Rounded display style for child-area labels drawn outside the theme.
  static const TextStyle childLabel = TextStyle(
    fontFamily: displayFont,
    fontFamilyFallback: displayFallback,
    fontWeight: FontWeight.w600,
    color: Palette.textSoft,
  );

  static ThemeData light({bool highContrast = false}) {
    final outline = highContrast ? Palette.outlineStrong : Palette.outline;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.coral,
        surface: Palette.cream,
      ),
      scaffoldBackgroundColor: Palette.cream,
    );

    TextStyle display(TextStyle? style, double size) =>
        (style ?? const TextStyle()).copyWith(
          fontFamily: displayFont,
          fontFamilyFallback: displayFallback,
          fontWeight: FontWeight.w600,
          fontSize: size,
          color: Palette.textDark,
        );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: Palette.textDark,
            displayColor: Palette.textDark,
          )
          .copyWith(
            headlineMedium: display(base.textTheme.headlineMedium, 26),
            titleLarge: display(base.textTheme.titleLarge, 21),
            titleMedium: display(base.textTheme.titleMedium, 17),
            titleSmall: display(base.textTheme.titleSmall, 15),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Palette.peach,
        foregroundColor: Palette.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: display(null, 22),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: highContrast ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: highContrast
              ? BorderSide(color: outline, width: 2)
              : BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          backgroundColor: Palette.coral,
          foregroundColor: Palette.textDark,
          textStyle: display(null, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(display(null, 13)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Palette.coral
              : Palette.disabled,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Palette.peach
              : Palette.cream,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Palette.coral,
        thumbColor: Palette.coral,
      ),
      dividerTheme: DividerThemeData(color: outline.withValues(alpha: 0.3)),
    );
  }
}
