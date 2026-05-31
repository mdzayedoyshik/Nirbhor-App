import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';
import '../models/app_config_model.dart';
import 'app_button.dart';

class AppUpdateSheet extends StatelessWidget {
  final PlatformConfig config;
  final String currentVersion;
  final bool forced;

  const AppUpdateSheet({
    super.key,
    required this.config,
    required this.currentVersion,
    required this.forced,
  });

  @override
  Widget build(BuildContext context) {
    final title = config.title.isNotEmpty ? config.title : 'Update Available';
    final message = config.message.isNotEmpty
        ? config.message
        : 'A new version of the app is available. Update now for the latest features and improvements.';

    return PopScope(
      canPop: !forced,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UpdateHeader(
            title: title,
            currentVersion: currentVersion,
            latestVersion: config.latestVersion,
            forced: forced,
          ),
          const SizedBox(height: AppSizing.md),
          Text(
            message,
            style: AppTypography.bodyM.copyWith(color: context.textSecColor),
          ),
          if (config.changelog.isNotEmpty) ...[
            const SizedBox(height: AppSizing.md),
            _ChangelogSection(items: config.changelog),
          ],
          const SizedBox(height: AppSizing.lg),
          AppButton(
            label: 'Update Now',
            onPressed: () => _launchUpdate(config.updateUrl),
            icon: const Icon(
              Icons.system_update_alt_rounded,
              size: AppSizing.iconSm,
              color: AppColors.white,
            ),
          ),
          if (!forced) ...[
            const SizedBox(height: AppSizing.sm),
            AppButton(
              label: 'Later',
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchUpdate(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _UpdateHeader extends StatelessWidget {
  final String title;
  final String currentVersion;
  final String latestVersion;
  final bool forced;

  const _UpdateHeader({
    required this.title,
    required this.currentVersion,
    required this.latestVersion,
    required this.forced,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          ),
          child: const Icon(
            Icons.system_update_rounded,
            color: AppColors.brand,
            size: AppSizing.iconLg,
          ),
        ),
        const SizedBox(width: AppSizing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTypography.h3.copyWith(color: context.textPrimColor)),
                  ),
                  if (forced)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.sm,
                        vertical: AppSizing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
                      ),
                      child: Text(
                        'Required',
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizing.xs),
              _VersionBadge(
                currentVersion: currentVersion,
                latestVersion: latestVersion,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;

  const _VersionBadge({
    required this.currentVersion,
    required this.latestVersion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VersionChip(
          label: 'v$currentVersion',
          color: context.textTerColor,
          bg: context.surfaceColor,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizing.xs),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: AppSizing.iconSm,
            color: context.textTerColor,
          ),
        ),
        _VersionChip(
          label: 'v$latestVersion',
          color: AppColors.success,
          bg: AppColors.success.withValues(alpha: 0.12),
        ),
      ],
    );
  }
}

class _VersionChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _VersionChip({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelS.copyWith(color: color),
      ),
    );
  }
}

class _ChangelogSection extends StatelessWidget {
  final List<String> items;

  const _ChangelogSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: AppSizing.iconSm,
                color: AppColors.brand,
              ),
              const SizedBox(width: AppSizing.xs),
              Text(
                "What's New",
                style: AppTypography.labelM.copyWith(color: AppColors.brand),
              ),
            ],
          ),
          const SizedBox(height: AppSizing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTypography.bodyS.copyWith(color: context.textSecColor),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyS.copyWith(color: context.textSecColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
