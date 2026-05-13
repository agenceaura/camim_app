import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color camimInk = Color(0xFF0A0A0A);
  static const Color camimAsh = Color(0xFF131313);
  static const Color camimSmoke = Color(0xFF1C1C1C);
  static const Color camimPaper = Color(0xFFF3EDE2);
  static const Color camimPaperHi = Color(0xFFFBF8F1);
  static const Color camimRed = Color(0xFFE1261C);
  static const Color camimRedDeep = Color(0xFFA01511);
  static const Color camimBlue = Color(0xFF1A3FB8);
  static const Color camimBlueDeep = Color(0xFF0E2270);
  static const Color camimTierra = Color(0xFFB94A1C);

  // Typography helpers
  static TextStyle displayFont({Color? color, double? fontSize, FontStyle? fontStyle, FontWeight? fontWeight}) {
    return GoogleFonts.archivoBlack(
      color: color,
      fontSize: fontSize,
      fontStyle: fontStyle ?? FontStyle.italic,
      fontWeight: fontWeight,
      letterSpacing: -0.04 * (fontSize ?? 16),
    );
  }

  static TextStyle subheadFont({Color? color, double? fontSize, FontStyle? fontStyle, FontWeight? fontWeight}) {
    return GoogleFonts.barlowCondensed(
      color: color,
      fontSize: fontSize,
      fontStyle: fontStyle ?? FontStyle.italic,
      fontWeight: fontWeight ?? FontWeight.w800,
      letterSpacing: 0.02 * (fontSize ?? 16),
    );
  }

  static TextStyle dataFont({Color? color, double? fontSize, FontWeight? fontWeight}) {
    return GoogleFonts.jetBrainsMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w700,
      letterSpacing: 0.18 * (fontSize ?? 16),
    );
  }

  static TextStyle bodyFont({Color? color, double? fontSize, FontWeight? fontWeight}) {
    return GoogleFonts.barlow(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: camimRed,
      scaffoldBackgroundColor: camimPaper,
      colorScheme: const ColorScheme.light(
        primary: camimRed,
        secondary: camimBlue,
        surface: camimPaperHi,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: camimInk,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: camimInk,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: subheadFont(fontSize: 24, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: camimRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          textStyle: dataFont(fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: camimRed,
        foregroundColor: Colors.white,
      ),
      textTheme: _buildTextTheme(Brightness.light),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: camimRed,
      scaffoldBackgroundColor: camimInk,
      colorScheme: const ColorScheme.dark(
        primary: camimRed,
        secondary: camimBlue,
        surface: camimAsh,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: camimAsh,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: subheadFont(fontSize: 24, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: camimRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          textStyle: dataFont(fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: camimRed,
        foregroundColor: Colors.white,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.dark ? Colors.white : camimInk;
    
    return TextTheme(
      displayLarge: displayFont(color: textColor, fontSize: 56),
      displayMedium: displayFont(color: textColor, fontSize: 48),
      displaySmall: displayFont(color: textColor, fontSize: 36),
      
      headlineLarge: subheadFont(color: textColor, fontSize: 32),
      headlineMedium: subheadFont(color: textColor, fontSize: 28),
      headlineSmall: subheadFont(color: textColor, fontSize: 24),
      
      titleLarge: subheadFont(color: textColor, fontSize: 22),
      titleMedium: dataFont(color: textColor, fontSize: 18),
      titleSmall: dataFont(color: textColor, fontSize: 14),
      
      bodyLarge: bodyFont(color: textColor, fontSize: 18),
      bodyMedium: bodyFont(color: textColor, fontSize: 16),
      bodySmall: bodyFont(color: textColor, fontSize: 14),
      
      labelLarge: dataFont(color: textColor, fontSize: 14),
      labelMedium: dataFont(color: textColor, fontSize: 12),
      labelSmall: dataFont(color: textColor, fontSize: 10),
    );
  }
}
