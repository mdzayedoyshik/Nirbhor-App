import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';
import '../network/connectivity_cubit.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool fullWidth;
  final Widget? icon;
  final double height;

  /// When true, the button is greyed-out and unpressable while the device is
  /// offline. Set this on buttons that perform a network write (submit, save,
  /// delete, …) so users can't trigger actions that would just fail offline.
  final bool offlineDisabled;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.fullWidth = true,
    this.icon,
    this.height = AppSizing.buttonHeight,
    this.offlineDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    // Only subscribe to connectivity when this button opts in (&& short-circuits).
    final offline =
        offlineDisabled && context.watch<ConnectivityCubit>().isOffline;
    final effectiveOnPressed = (loading || offline) ? null : onPressed;
    final child = loading
        ? const SizedBox(
            width: AppSizing.spinnerSize,
            height: AppSizing.spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: AppSizing.borderWidthLg,
              color: AppColors.white,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: AppSizing.sm), Text(label, style: _labelStyle)],
              )
            : Text(label, style: _labelStyle);

    Widget button;

    final minWidth = fullWidth ? double.infinity : 0.0;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
            minimumSize: Size(minWidth, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            elevation: 0,
          ),
          child: child,
        );
        break;

      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.surfaceColor,
            foregroundColor: context.textPrimColor,
            minimumSize: Size(minWidth, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
            elevation: 0,
          ),
          child: child,
        );
        break;

      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            minimumSize: Size(minWidth, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
            ),
          ),
          child: child,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(0, height),
          ),
          child: child,
        );
        break;
    }

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  TextStyle get _labelStyle {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppTypography.titleMedium.copyWith(color: AppColors.white);
      case AppButtonVariant.secondary:
        return AppTypography.titleMedium;
      case AppButtonVariant.outlined:
        return AppTypography.titleMedium.copyWith(color: AppColors.primary);
      case AppButtonVariant.text:
        return AppTypography.titleMedium.copyWith(color: AppColors.primary);
    }
  }
}
