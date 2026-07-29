import 'package:flutter/material.dart';

/// Warm pastel palette shared by widgets and Flame scenes.
///
/// Everything is soft and rounded; avoid saturated alarm colours. When
/// high-contrast mode is on, use [outlineStrong] for interactive borders.
class Palette {
  Palette._();

  // Backgrounds
  static const cream = Color(0xFFFFF6EA);
  static const skyDay = Color(0xFFBEE3F0);
  static const skyEvening = Color(0xFF9DA8D8);
  static const skyNight = Color(0xFF4A5580);
  static const underwater = Color(0xFFA8D8E4);
  static const meadow = Color(0xFFCDE8C4);

  // Accents
  static const peach = Color(0xFFFFD9B8);
  static const coral = Color(0xFFFFB59E);
  static const butter = Color(0xFFFFE9A8);
  static const mint = Color(0xFFBFE8D2);
  static const lavender = Color(0xFFDCCDF0);
  static const blush = Color(0xFFF8CFDA);
  static const babyBlue = Color(0xFFB5D8F0);

  // Game object colours (soft but distinguishable)
  static const softRed = Color(0xFFF29E97);
  static const softBlue = Color(0xFF8FBEE8);
  static const softYellow = Color(0xFFF7DD84);
  static const softGreen = Color(0xFFA5D6A0);
  static const softOrange = Color(0xFFF7BE8B);
  static const softPurple = Color(0xFFC3A8E0);
  static const softPink = Color(0xFFF2B8CE);
  static const softBrown = Color(0xFFC9A186);

  // Milo
  static const miloBody = Color(0xFFF7C59A);
  static const miloBelly = Color(0xFFFFF0DC);
  static const miloEar = Color(0xFFF2AD7E);
  static const miloCheek = Color(0xFFF7A8A0);

  // Lines and text
  static const outline = Color(0xFF9A8271);
  static const outlineStrong = Color(0xFF5D4E42);
  static const textDark = Color(0xFF5D4E42);
  static const textSoft = Color(0xFF8A7A6C);

  /// Star / reward gold.
  static const starGold = Color(0xFFF7D774);

  /// Softly muted color for disabled/locked items.
  static const disabled = Color(0xFFD9D2C9);
}
