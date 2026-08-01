import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFFFF6D00); // Vibrant Food Orange
  static const Color primaryVariant = Color(0xFFE65100);
  static const Color secondary = Color(0xFF00C853); // Emerald Sales Green
  static const Color secondaryVariant = Color(0xFF009624);
  static const Color accent = Color(0xFFFFD600); // Gold Accent

  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF3D00);
  static const Color info = Color(0xFF29B6F6);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF12131A);
  static const Color darkSurface = Color(0xFF1E1F2B);
  static const Color darkCard = Color(0xFF272938);
  static const Color darkBorder = Color(0xFF35384B);
  static const Color darkTextPrimary = Color(0xFFF1F3F9);
  static const Color darkTextSecondary = Color(0xFF9E9EAF);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1A202C);
  static const Color lightTextSecondary = Color(0xFF718096);

  // Category & Veg/Non-Veg Badges
  static const Color vegGreen = Color(0xFF2E7D32);
  static const Color nonVegRed = Color(0xFFC62828);

  // Modern UI & Shimmer Tokens
  static const Color darkCardHover = Color(0xFF2E3144);
  static const Color shimmerBaseDark = Color(0xFF1E202C);
  static const Color shimmerHighlightDark = Color(0xFF2E3144);
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF8FAFC);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFAB00), Color(0xFFFFD600)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF272938), Color(0xFF1E1F2B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
