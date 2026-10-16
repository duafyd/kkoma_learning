import 'package:flutter/material.dart';

/// A small shared palette; content-specific illustrations remain in features.
abstract final class StorybookTheme {
  static const ink = Color(0xff283b49);
  static const paper = Color(0xfffaf7ef);
  static const teal = Color(0xff17776b);
  static const gold = Color(0xffefb94d);
  static const line = Color(0xffe7e7dd);

  static ThemeData get data {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: teal),
    );
    return base.copyWith(
      scaffoldBackgroundColor: paper,
      colorScheme: base.colorScheme.copyWith(
        primary: teal,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: ink,
      ),
      textTheme: base.textTheme
          .apply(bodyColor: ink, displayColor: ink)
          .copyWith(
            headlineMedium: const TextStyle(
              fontFamily: 'Jua',
              fontSize: 34,
              height: 1.2,
              color: ink,
            ),
            titleLarge: const TextStyle(
              fontFamily: 'Jua',
              fontSize: 24,
              color: ink,
            ),
            titleMedium: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
            bodyLarge: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              height: 1.5,
              color: ink,
            ),
            bodyMedium: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              height: 1.45,
              color: ink,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(fontFamily: 'Jua', fontSize: 25, color: ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 60),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontFamily: 'Jua', fontSize: 21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 60),
          backgroundColor: Colors.white,
          foregroundColor: ink,
          side: const BorderSide(color: line),
          textStyle: const TextStyle(fontFamily: 'Jua', fontSize: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(60, 52),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(60, 60)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
