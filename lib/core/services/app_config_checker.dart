import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_update_sheet.dart';
import '../widgets/maintenance_overlay.dart';
import 'remote_config_service.dart';

class AppConfigChecker {
  AppConfigChecker._();

  static Future<void> check(BuildContext context) async {
    final config = RemoteConfigService.instance.config;

    // 1. Maintenance check — blocks everything else.
    if (config.maintenance.isEnabled) {
      final title = config.maintenance.title.isNotEmpty
          ? config.maintenance.title
          : 'App Under Maintenance';
      final message = config.maintenance.message.isNotEmpty
          ? config.maintenance.message
          : "We're working on something. Please check back soon.";

      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => MaintenanceOverlay(title: title, message: message),
        );
      }
      return;
    }

    // 2. Version check — only on mobile.
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final platform = Platform.isIOS ? config.ios : config.android;
    if (!platform.isUpdateEnabled) return;

    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    log('[AppConfigChecker] Current version: $current, Remote config: ${platform.latestVersion}');
    if (!context.mounted) return;

    if (_isOlderThan(current, platform.minVersion)) {
      log('[RemoteConfig] Forcing update: current=$current, min=${platform.minVersion}, latest=${platform.latestVersion}');
      // Forced update — user must update to continue.
      await AppBottomSheet.show<void>(
        context: context,
        isDismissible: false,
        child: AppUpdateSheet(
          config: platform,
          currentVersion: current,
          forced: true,
        ),
      );
    } else if (_isOlderThan(current, platform.latestVersion)) {
      log('[RemoteConfig] Optional update: current=$current, latest=${platform.latestVersion}');
      // Optional update — user can dismiss.
      await AppBottomSheet.show<void>(
        context: context,
        child: AppUpdateSheet(
          config: platform,
          currentVersion: current,
          forced: false,
        ),
      );
    }
  }

  /// Returns true if semver [a] is strictly older than [b].
  static bool _isOlderThan(String a, String b) {
    final aParts = _parseSemver(a);
    final bParts = _parseSemver(b);
    for (var i = 0; i < 3; i++) {
      if (aParts[i] < bParts[i]) return true;
      if (aParts[i] > bParts[i]) return false;
    }
    return false;
  }

  static List<int> _parseSemver(String version) {
    final parts = version.split('.');
    return List.generate(3, (i) {
      if (i >= parts.length) return 0;
      return int.tryParse(parts[i]) ?? 0;
    });
  }
}
