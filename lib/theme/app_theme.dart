import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundBlack = Colors.black;
  static const Color textBlack = Color(0xFF121212);
  static const Color textWhite = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: backgroundWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        secondary: primaryBlue,
        surface: backgroundWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundBlack,
        foregroundColor: textWhite,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: textWhite,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: textWhite,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textBlack, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textBlack, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textBlack),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: primaryBlue,
        surface: Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundBlack,
        foregroundColor: textWhite,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: textWhite,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: textWhite,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textWhite),
      ),
    );
  }
}
