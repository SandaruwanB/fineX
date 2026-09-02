import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color wealthGreen = Color(0xFF059669); // Deep Emerald Primary
  static const Color emeraldGreen = Color(0xFF10B981); // Bright Spring Emerald
  static const Color wealthGreenMuted = Color(0xFF047857); // Forest Emerald
  static const Color wealthGreenDark = Color(0xFF064E3B); // Deep Vault Green

  // Trust Navy & Precision Accents
  static const Color trustNavy = Color(0xFF1E293B); // Slate Navy
  static const Color neonBlue = Color(0xFF0EA5E9); // Precision Sky Azure
  static const Color electricIndigo = Color(0xFF6366F1); // Neo Violet
  static const Color dangerRed = Color(0xFFEF4444); // Loss / Debit Red
  static const Color goldAccent = Color(0xFFF59E0B); // Brushed Gold
  static const Color copperAccent = Color(0xFFD97706); // Rich Copper
  static const Color purpleAccent = Color(0xFF8B5CF6); // Royal Violet

  // Light Theme Palette (Pure Minimalist Quartz & Titanium)
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F5F9);
  static const Color lightPrimary = Color(0xFF0F172A);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Theme Palette (High-Contrast Obsidian Slate - Battery Efficient)
  static const Color darkBg = Color(0xFF070A10); // Deepest Obsidian
  static const Color darkSurface = Color(0xFF101726); // Titanium Slate Navy
  static const Color darkSurfaceSecondary = Color(0xFF182234); // Elevated Container
  static const Color darkSurfaceHighlight = Color(0xFF223048); // Skeuomorphic Highlight
  static const Color darkPrimary = Color(0xFF10B981); // Crisp Emerald
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkBorderHighlight = Color(0xFF334155);

  // --- Executive Gradients ---
  static const LinearGradient wealthEmeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF064E3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient titaniumCardDark = LinearGradient(
    colors: [Color(0xFF182234), Color(0xFF101726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient obsidianBlackCard = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF070A10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldMetallicGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient platinumGradient = LinearGradient(
    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme => getLightTheme('Outfit');
  static ThemeData get darkTheme => getDarkTheme('Outfit');

  static TextTheme _buildTextTheme(String font, TextTheme baseTheme, Color textPrimary, Color textSecondary) {
    TextTheme googleTheme;
    switch (font) {
      case 'Inter':
        googleTheme = GoogleFonts.interTextTheme(baseTheme);
        break;
      case 'Plus Jakarta Sans':
        googleTheme = GoogleFonts.plusJakartaSansTextTheme(baseTheme);
        break;
      case 'Poppins':
        googleTheme = GoogleFonts.poppinsTextTheme(baseTheme);
        break;
      case 'Outfit':
      default:
        googleTheme = GoogleFonts.outfitTextTheme(baseTheme);
        break;
    }
    return googleTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );
  }

  static ThemeData getLightTheme(String font) {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    final textTheme = _buildTextTheme(font, base.textTheme, lightTextPrimary, lightTextSecondary);

    return base.copyWith(
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: wealthGreen,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
        error: dangerRed,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: lightBorder, width: 1.0),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: wealthGreen,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: wealthGreen, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme(String font) {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final textTheme = _buildTextTheme(font, base.textTheme, darkTextPrimary, darkTextSecondary);

    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: neonBlue,
        surface: darkSurface,
        onPrimary: Color(0xFF070A10),
        onSurface: darkTextPrimary,
        error: dangerRed,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkBorder, width: 1.0),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF070A10),
          elevation: 0,
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emeraldGreen, width: 1.5),
        ),
      ),
    );
  }
}
