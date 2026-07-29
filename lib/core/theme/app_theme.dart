import 'package:flutter/material.dart';

import 'palette.dart';

/// Material theme for parent screens plus shared child-area styling.
class AppTheme {
  AppTheme._();

  static ThemeData light({bool highContrast = false}) {
    final outline = highContrast ? Palette.outlineStrong : Palette.outline;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.coral,
        surface: Palette.cream,
      ),
      scaffoldBackgroundColor: Palette.cream,
      fontFamily: null,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: Palette.textDark,
        displayColor: Palette.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.peach,
        foregroundColor: Palette.textDark,
        elevation: 0,
        centerTitle: true,
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
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
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
