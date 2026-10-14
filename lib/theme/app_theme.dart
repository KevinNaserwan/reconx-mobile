import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color dangerRose = Color(0xFFF43F5E);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF020617);
  static const Color darkCard = Color(0xFF0B1120);
  static const Color darkCardBorder = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Theme Config
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: primaryEmerald,
    cardColor: darkCard,
    colorScheme: const ColorScheme.dark(
      primary: primaryEmerald,
      secondary: primaryCyan,
      surface: darkCard,
      background: darkBg,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      titleLarge: GoogleFonts.plusJakartaSans(
        color: darkTextPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: darkTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: darkTextPrimary,
        fontSize: 14,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: darkTextSecondary,
        fontSize: 12,
      ),
    ),
  );

  // Light Theme Config
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: primaryEmerald,
    cardColor: lightCard,
    colorScheme: const ColorScheme.light(
      primary: primaryEmerald,
      secondary: primaryTeal,
      surface: lightCard,
      background: lightBg,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    ).copyWith(
      titleLarge: GoogleFonts.plusJakartaSans(
        color: lightTextPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: lightTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: lightTextPrimary,
        fontSize: 14,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: lightTextSecondary,
        fontSize: 12,
      ),
    ),
  );
}
