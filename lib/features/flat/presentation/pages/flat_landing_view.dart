import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';

class FlatLandingView extends StatelessWidget {
  const FlatLandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizing.pagePadding),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.apartment_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizing.lg),
            Text(
              AppStrings.noFlatTitle,
              style: AppTypography.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizing.sm),
            Text(
              AppStrings.noFlatSubtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecColor,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 3),
            AppButton(
              label: AppStrings.createFlatLabel,
              onPressed: () => context.push(AppRoutes.flatCreate),
              icon: const Icon(Icons.add, color: AppColors.white),
            ),
            const SizedBox(height: AppSizing.md),
            AppButton(
              label: AppStrings.joinFlatLabel,
              variant: AppButtonVariant.outlined,
              onPressed: () => context.push(AppRoutes.flatJoin),
              icon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
            ),
            const SizedBox(height: AppSizing.xl),
          ],
        ),
      ),
    );
  }
}
