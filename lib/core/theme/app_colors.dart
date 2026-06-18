import 'package:flutter/material.dart';

/// CalorieApp design system — color tokens.
///
/// Warm, appetite-positive palette. Greens for "go", ambers for caution,
/// corals for celebration. Avoid the clinical blue/white of health apps.
class AppColors {
  AppColors._();

  // Brand
  static const Color brand = Color(0xFFFF6B35);          // warm coral
  static const Color brandDark = Color(0xFFE85A2C);
  static const Color brandLight = Color(0xFFFF8A5C);
  static const Color brandSoft = Color(0xFFFFF1EB);

  // Accents
  static const Color mint = Color(0xFF00C896);           // progress success
  static const Color mintSoft = Color(0xFFE6FAF4);
  static const Color amber = Color(0xFFFFB627);          // caution
  static const Color lavender = Color(0xFF8B7FFF);       // protein
  static const Color sky = Color(0xFF4FC3F7);            // carbs
  static const Color rose = Color(0xFFFF6B9D);           // fat

  // Surfaces
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F5F7);
  static const Color divider = Color(0xFFEAEAEA);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFFA0A0A0);
  static const Color textOnBrand = Colors.white;

  // Semantic
  static const Color success = mint;
  static const Color warning = amber;
  static const Color error = Color(0xFFE53935);
  static const Color info = sky;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8A5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF4FE3B5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFB627), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}