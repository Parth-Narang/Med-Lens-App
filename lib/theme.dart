import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedVerifyTheme {
  // --- Colors (Derived from src/styles/theme.css) ---
  static const Color primaryBlue = Color(0xFF2260FF); // --primary
  static const Color successGreen = Color(0xFF10B981); // --success-green
  static const Color warningRed = Color(0xFFEF4444); // --warning-red
  static const Color bgGray = Color(0xFFF9FAFB); // Gray-50/Background
  static const Color textMain = Color(0xFF111827); // Gray-900 for text
  static const Color textMuted = Color(0xFF6B7280); // Gray-500 for captions

  // --- ThemeData ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: bgGray,

      // Font settings
      fontFamily: GoogleFonts.inter().fontFamily,

      // FIX 1: Change 'CardTheme' to 'CardThemeData'
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Text Theme mapping
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textMain,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textMain,
        ),
        bodySmall: TextStyle(fontSize: 14, color: textMuted),
      ),

      // FIX 2: Correct method name to 'ElevatedButton.styleFrom'
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
