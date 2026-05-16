import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';
import 'app_button.dart';

class AppDialog {
  AppDialog._();

  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        title: Text(title, style: AppTypography.headlineSmall),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          AppButton(
            label: cancelLabel,
            variant: AppButtonVariant.text,
            fullWidth: false,
            height: AppSizing.buttonHeightSm,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            label: confirmLabel,
            variant: destructive
                ? AppButtonVariant.text
                : AppButtonVariant.primary,
            fullWidth: false,
            height: AppSizing.buttonHeightSm,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  static Future<void> info({
    required BuildContext context,
    required String title,
    required String message,
    String okLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        title: Text(title, style: AppTypography.headlineSmall),
        content: Text(message, style: AppTypography.bodyMedium),
        actions: [
          AppButton(
            label: okLabel,
            variant: AppButtonVariant.text,
            fullWidth: false,
            height: AppSizing.buttonHeightSm,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
