import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF0F1740);
  static const Color textColor = Colors.white;

  static ThemeData get akhigptTheme {
    return ThemeData(
      scaffoldBackgroundColor: backgroundColor,
      primarySwatch: Colors.blue,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lexend(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        displayMedium: GoogleFonts.lexend(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        displaySmall: GoogleFonts.lexend(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        headlineLarge: GoogleFonts.lexend(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.lexend(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        headlineSmall: GoogleFonts.lexend(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleLarge: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleMedium: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleSmall: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodySmall: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        labelLarge: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        labelMedium: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        labelSmall: GoogleFonts.lexend(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  // Keep backward compatibility
  static ThemeData get theme => akhigptTheme;
}
