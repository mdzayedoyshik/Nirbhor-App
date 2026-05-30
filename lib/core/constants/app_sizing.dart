class AppSizing {
  AppSizing._();

  // ─── Spacing tokens ───────────────────────────────────────────────────────
  static const double sp2 = 2.0;
  static const double sp4 = 4.0;
  static const double sp8 = 8.0;
  static const double sp12 = 12.0;
  static const double sp16 = 16.0;
  static const double sp20 = 20.0;
  static const double sp24 = 24.0;
  static const double sp32 = 32.0;
  static const double sp48 = 48.0;
  static const double sp64 = 64.0;

  // ─── Border-radius tokens ─────────────────────────────────────────────────
  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double rFull = 999.0;

  // ─── Component dimensions ─────────────────────────────────────────────────
  static const double buttonHeight = 52.0;
  static const double inputHeight = 56.0;
  static const double bottomNavHeight = 64.0;
  static const double appBarHeight = 56.0;

  // ─── Avatar sizes ─────────────────────────────────────────────────────────
  static const double avatar24 = 24.0;
  static const double avatar32 = 32.0;
  static const double avatar40 = 40.0;
  static const double avatar52 = 52.0;
  static const double avatar64 = 64.0;
  static const double avatar80 = 80.0;

  // ─── Page padding ─────────────────────────────────────────────────────────
  static const double pagePadding = 20.0;

  // ─── Icon sizes ───────────────────────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 64.0;

  // ─── OTP field ────────────────────────────────────────────────────────────
  static const double otpFieldWidth = 52.0;
  static const double otpFieldHeight = 60.0;

  // ─── Bottom sheet drag handle ─────────────────────────────────────────────
  static const double bottomSheetHandleWidth = 40.0;
  static const double bottomSheetHandleHeight = 4.0;

  // ─── Misc ─────────────────────────────────────────────────────────────────
  static const double spinnerSize = 20.0;
  static const double borderWidth = 1.0;
  static const double borderWidthMd = 1.5;
  static const double borderWidthLg = 2.0;

  // ─── Backward-compat aliases (used across existing feature files) ─────────
  static const double xs = sp4;
  static const double sm = sp8;
  static const double md = sp16;
  static const double lg = sp24;
  static const double xl = sp32;
  static const double xxl = sp48;

  static const double radiusSm = r8;
  static const double radiusMd = r12;
  static const double radiusLg = r16;
  static const double radiusXl = r24;
  static const double radiusFull = rFull;

  static const double buttonHeightSm = 40.0;

  /// Previously inputHeight was 52; now 56. Alias kept so old refs compile.
  // (inputHeight already defined above as 56)

  /// avatarRadius was used as a radius value (half of diameter).
  static const double avatarRadius = 40.0;
}
