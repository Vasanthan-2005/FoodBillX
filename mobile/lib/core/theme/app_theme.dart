import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Available app themes.
enum AppThemeMode { dark, light, saffronDark, emeraldDark }

class AppTheme {
  /// Returns the [ThemeData] for the given [AppThemeMode].
  static ThemeData getTheme(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.dark => darkTheme,
      AppThemeMode.light => lightTheme,
      AppThemeMode.saffronDark => saffronDarkTheme,
      AppThemeMode.emeraldDark => emeraldDarkTheme,
    };
  }

  // ─────────────────────────────────────────────────────────────────
  // Light Theme
  // ─────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme)
          .copyWith(
            displayLarge: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextPrimary,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
            bodyLarge: const TextStyle(color: AppColors.lightTextPrimary),
            bodyMedium: const TextStyle(color: AppColors.lightTextSecondary),
          ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Dark Theme (Default)
  // ─────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.darkTextPrimary,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextPrimary,
            ),
            bodyLarge: const TextStyle(color: AppColors.darkTextPrimary),
            bodyMedium: const TextStyle(color: AppColors.darkTextSecondary),
          ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Saffron Dark Theme
  // ─────────────────────────────────────────────────────────────────
  static ThemeData get saffronDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.saffronPrimary,
        secondary: AppColors.saffronSecondary,
        surface: AppColors.saffronSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.saffronTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.saffronBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.saffronTextPrimary,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.saffronTextPrimary,
            ),
            bodyLarge: const TextStyle(color: AppColors.saffronTextPrimary),
            bodyMedium: const TextStyle(color: AppColors.saffronTextSecondary),
          ),
      cardTheme: CardThemeData(
        color: AppColors.saffronCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.saffronBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.saffronSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.saffronTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.saffronTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.saffronPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.saffronSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.saffronBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.saffronBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.saffronPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Emerald Dark Theme
  // ─────────────────────────────────────────────────────────────────
  static ThemeData get emeraldDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emeraldPrimary,
        secondary: AppColors.emeraldSecondary,
        surface: AppColors.emeraldSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.emeraldTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.emeraldBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.emeraldTextPrimary,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.emeraldTextPrimary,
            ),
            bodyLarge: const TextStyle(color: AppColors.emeraldTextPrimary),
            bodyMedium: const TextStyle(color: AppColors.emeraldTextSecondary),
          ),
      cardTheme: CardThemeData(
        color: AppColors.emeraldCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.emeraldBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.emeraldSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.emeraldTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.emeraldTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emeraldPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.emeraldSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.emeraldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.emeraldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.emeraldPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
