import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../network/connectivity_cubit.dart';

/// Wraps the whole app (via `MaterialApp.router`'s `builder`) and shows a slim,
/// persistent bar pinned to the bottom whenever the device is offline.
///
/// It lives below the entire navigator, so it never overlaps an AppBar or the
/// bottom nav — when offline the content gently shrinks to make room, and the
/// bar animates away the moment connectivity returns. Shown on every screen.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) {
        final offline = status == ConnectivityStatus.offline;
        return Column(
          children: [
            Expanded(child: child),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: offline
                  ? const _OfflineBar()
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.textPrimary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 15, color: AppColors.white),
              const SizedBox(width: 8),
              Text(
                AppStrings.offlineBanner,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
