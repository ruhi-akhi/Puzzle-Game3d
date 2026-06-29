import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_colors.dart';

class AppTheme {
  static ThemeData get darkSciFi {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GameColors.background,
      colorScheme: const ColorScheme.dark(
        primary: GameColors.neonCyan,
        secondary: GameColors.neonPink,
        surface: Color(0xFF111827),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: GameColors.hudText,
      ),
      textTheme: GoogleFonts.orbitronTextTheme(
        TextTheme(
          displayLarge: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: GameColors.neonCyan,
            letterSpacing: 4,
          ),
          displayMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: GameColors.neonCyan,
            letterSpacing: 2,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: GameColors.hudText,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            color: GameColors.hudText,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: GameColors.hudText.withOpacity(0.8),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: GameColors.neonCyan,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: GameColors.neonCyan, width: 2),
          ),
        ),
      ),
    );
  }
}
