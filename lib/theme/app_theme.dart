import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AppTheme {
  // ✨ ORIGINAL COLOR PALETTE - Keeping exact original colors
  static const Color primaryCream = Color(0xFFFCF8F1);
  static const Color secondaryCream = Color(0xFFF5F0E8);
  static const Color darkCream = Color(0xFFE8E0D8);
  static const Color warmBrown = Color(0xFF9C6644);
  static const Color darkBrown = Color(0xFF8B5A3C);
  static const Color textDark = Color(0xFF4F372D);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);

  // ✨ GLASSMORPHISM COLORS - Using original color scheme
  static const Color glassWhite = Color(0x40FFFFFF);
  static const Color glassCream = Color(0x30FCF8F1);
  static const Color glassBrown = Color(0x209C6644);

  // ✨ NEUMORPHISM SHADOWS - Reduced for better performance and cleaner look
  static List<BoxShadow> get neumorphicShadowsLight => [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.6),
      offset: const Offset(-2, -2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: darkCream.withValues(alpha: 0.2),
      offset: const Offset(2, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get neumorphicShadowsPressed => [
    BoxShadow(
      color: darkCream.withValues(alpha: 0.3),
      offset: const Offset(-1, -1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.4),
      offset: const Offset(1, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  // ✨ CARD SHADOWS - Lighter for better performance
  static List<BoxShadow> get cardShadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static ThemeData get companionTheme {
    return ThemeData(
      scaffoldBackgroundColor: primaryCream,
      primarySwatch: Colors.brown,
      primaryColor: warmBrown,
      colorScheme: ColorScheme.fromSeed(
        seedColor: warmBrown,
        brightness: Brightness.light,
        surface: primaryCream,
        onSurface: textDark,
      ),
      textTheme: TextTheme(
        // ✨ BOLD OVERSIZED HEADLINES
        displayLarge: GoogleFonts.lexend(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: textDark,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.lexend(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.lexend(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.25,
        ),
        headlineLarge: GoogleFonts.lexend(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.lexend(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.25,
        ),
        headlineSmall: GoogleFonts.lexend(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.25,
        ),
        titleLarge: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.1,
        ),
        titleMedium: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.1,
        ),
        titleSmall: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textDark,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textMedium,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textLight,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMedium,
          letterSpacing: 0.1,
        ),
        labelSmall: GoogleFonts.lexend(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textLight,
          letterSpacing: 0.1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: warmBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.all(8),
      ),
    );
  }

  // ✨ GLASSMORPHISM DECORATION
  static BoxDecoration glassmorphicDecoration({
    Color? color,
    double borderRadius = 16,
    double borderWidth = 1,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? glassWhite,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.2),
        width: borderWidth,
      ),
      boxShadow: cardShadows,
    );
  }

  // ✨ NEUMORPHIC DECORATION
  static BoxDecoration neumorphicDecoration({
    Color? color,
    double borderRadius = 16,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: color ?? primaryCream,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isPressed ? neumorphicShadowsPressed : neumorphicShadowsLight,
    );
  }

  // ✨ CARD DECORATION
  static BoxDecoration cardDecoration({
    Color? color,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: cardShadows,
    );
  }

  // Keep backward compatibility
  static ThemeData get theme => companionTheme;
  static ThemeData get akhigptTheme => companionTheme; // Legacy support
}
