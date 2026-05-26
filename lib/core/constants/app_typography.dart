import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All text styles use Plus Jakarta Sans (via google_fonts).
/// Colors are intentionally omitted — applied by the theme or call-site.
class AppTypography {
  AppTypography._();

  // ─── Display ─────────────────────────────────────────────────────────────
  static TextStyle get displayXL => GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get displayL => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get displayM => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      );

  // ─── Headings ─────────────────────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get h4 => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  // ─── Body ────────────────────────────────────────────────────────────────
  static TextStyle get bodyL => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyM => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyS => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  // ─── Labels ──────────────────────────────────────────────────────────────
  static TextStyle get labelL => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelM => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelS => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

  // ─── Special ─────────────────────────────────────────────────────────────
  static TextStyle get overline => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      );

  // ─── Amount / Financial ───────────────────────────────────────────────────
  static TextStyle get amountXL => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get amountL => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get amountM => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get amountS => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  // ─── Backward-compat aliases (used across existing feature files) ─────────
  // These mirror the old Poppins names so existing code compiles unchanged.

  static TextStyle get displayLarge => displayL;
  static TextStyle get displayMedium => displayM;

  static TextStyle get headlineLarge => h1;
  static TextStyle get headlineMedium => h2;
  static TextStyle get headlineSmall => h3;

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyLarge => bodyL;
  static TextStyle get bodyMedium => bodyM;

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get labelLarge => labelL;

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );
}
