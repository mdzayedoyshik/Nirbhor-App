import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';

class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool isScrollControlled = true,
    bool? enableDrag,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag ?? isDismissible,
      backgroundColor: context.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusXl),
        ),
      ),
      builder: (builderContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(builderContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSizing.sm),
                width: AppSizing.bottomSheetHandleWidth,
                height: AppSizing.bottomSheetHandleHeight,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                ),
              ),
            ),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizing.pagePadding,
                  AppSizing.md,
                  AppSizing.pagePadding,
                  0,
                ),
                child: Text(title, style: AppTypography.headlineSmall),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
