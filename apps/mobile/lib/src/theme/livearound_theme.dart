import 'package:flutter/material.dart';

class LiveAroundTheme {
  const LiveAroundTheme._();

  static const Color ink = Color(0xFF15171A);
  static const Color surface = Color(0xFFF7F4EF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF1C7C7D);
  static const Color coral = Color(0xFFE85D4F);
  static const Color gold = Color(0xFFF3B340);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal,
      primary: teal,
      secondary: coral,
      tertiary: gold,
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: teal.withValues(alpha: 0.14),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
