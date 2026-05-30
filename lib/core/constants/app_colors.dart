import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Brand ───────────────────────────────────────────────────────────────
  static const Color brand = Color(0xFF4F6EF7);
  static const Color brandAccent = Color(0xFF7C3AED);

  // ─── Light Surface Scale ─────────────────────────────────────────────────
  static const Color surface50 = Color(0xFFF8F9FF);
  static const Color surface100 = Color(0xFFF0F4FF);
  static const Color surface200 = Color(0xFFE4EAFF);
  static const Color surface300 = Color(0xFFCDD5F3);

  // ─── Light Text ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F1523);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textTertiary = Color(0xFF8492A6);
  static const Color textDisabled = Color(0xFFB8C4D6);

  // ─── Semantic ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Meal Tags ───────────────────────────────────────────────────────────
  static const Color mealBreakfast = Color(0xFFFBBF24);
  static const Color mealLunch = Color(0xFF34D399);
  static const Color mealDinner = Color(0xFF818CF8);

  // ─── Dark Mode ───────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0A0D1A);
  static const Color darkSurface800 = Color(0xFF111627);
  static const Color darkSurface700 = Color(0xFF1A2140);
  static const Color darkSurface600 = Color(0xFF202B4E);
  static const Color darkSurface500 = Color(0xFF2A3660);
  static const Color darkTextPrimary = Color(0xFFF0F4FF);
  static const Color darkTextSecondary = Color(0xFF94A3C8);
  static const Color darkTextTertiary = Color(0xFF5A6A8A);

  // ─── Primitives ──────────────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;

  // ─── Gradients ───────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF4F6EF7), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softCardGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F4F6EF7),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A4F6EF7),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x244F6EF7),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowBrand = [
    BoxShadow(
      color: Color(0x4D4F6EF7),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];

  // ─── Helpers ─────────────────────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color adaptiveTextPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color adaptiveTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color adaptiveSurface(BuildContext context) =>
      isDark(context) ? darkSurface800 : surface100;

  static Color adaptiveBackground(BuildContext context) =>
      isDark(context) ? darkBg : surface50;

  // ─── Backward-compat aliases (used across existing feature files) ─────────
  /// Previously Color(0xFF6C63FF) — now maps to brand blue.
  static const Color primary = brand;

  /// Previously Color(0xFF3D35B8) — now maps to brandAccent purple.
  static const Color primaryDark = brandAccent;

  /// Previously accent pink — kept as a named constant for any remaining refs.
  static const Color accent = Color(0xFFFF6584);

  /// Previously background grey — maps to light surface50.
  static const Color background = surface50;

  /// Previously white surface.
  static const Color surface = white;

  /// Previously surfaceVariant — maps to surface100.
  static const Color surfaceVariant = surface100;

  /// Previously textHint — maps to textDisabled.
  static const Color textHint = textDisabled;

  /// Previously border grey.
  static const Color border = Color(0xFFE5E7EB);

  /// Previously divider grey.
  static const Color divider = surface200;
}

/// Extension for adaptive (theme-aware) color access.
extension AppColorsX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor => isDarkMode ? AppColors.darkBg : AppColors.surface50;
  Color get cardColor => isDarkMode ? AppColors.darkSurface800 : AppColors.white;
  Color get surfaceColor => isDarkMode ? AppColors.darkSurface700 : AppColors.surface100;
  Color get borderColor => isDarkMode ? AppColors.darkSurface600 : const Color(0xFFE5E7EB);
  Color get dividerColor => isDarkMode ? AppColors.darkSurface600 : AppColors.surface200;
  Color get textPrimColor => isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecColor => isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textTerColor => isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary;
  Color get bottomNavBg => isDarkMode ? AppColors.darkSurface800 : AppColors.white;
  Color get sheetBg => isDarkMode ? AppColors.darkSurface800 : AppColors.white;
}
