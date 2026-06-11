import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';
import '../router/app_router.dart';
import '../services/review_service.dart';
import 'app_button.dart';

/// The two-step "soft ask" used by world-class apps:
///   1. Ask privately: *"Enjoying Nirbhor?"*
///   2. If they love it → fire the NATIVE store-review sheet (submits straight
///      to Google Play / App Store).
///      If not → route them to the in-app Feedback form, so unhappy sentiment
///      becomes private feedback instead of a 1-star public review.
///
/// We never call the native sheet cold: Google/Apple throttle it and you can't
/// tell whether the user rated, so a cold call wastes the one chance and can't
/// be followed up. The pre-prompt fixes both.
class ReviewPrompt {
  ReviewPrompt._();

  // At most one review check per app process. MainShell is rebuilt on every
  // top-level tab (the router uses flat routes, not a ShellRoute), so the gate
  // can mount many times — this flag guarantees we only ever check once.
  static bool _checkedThisSession = false;

  static Future<void> maybeAsk(BuildContext context) async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    if (!await ReviewService.instance.shouldPrompt()) return;
    if (!context.mounted) return;

    // Count the ask now: starts the cooldown even if the user just dismisses it.
    await ReviewService.instance.markPrompted();
    if (!context.mounted) return;

    final liked = await showDialog<bool>(
      context: context,
      builder: (_) => const _EnjoyingDialog(),
    );

    if (liked == true) {
      await ReviewService.instance.markDone();
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing();
      }
    } else if (liked == false) {
      await ReviewService.instance.markDone();
      if (context.mounted) context.push(AppRoutes.feedback);
    }
    // Dismissed (null): leave it — the cooldown will surface it again later,
    // up to the hard cap in ReviewService.
  }
}

class _EnjoyingDialog extends StatelessWidget {
  const _EnjoyingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusXl),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        AppSizing.lg,
        AppSizing.pagePadding,
        AppSizing.md,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded,
                size: AppSizing.iconLg, color: AppColors.white),
          ),
          const SizedBox(height: AppSizing.md),
          Text(
            'Enjoying Nirbhor?',
            style: AppTypography.h3.copyWith(color: context.textPrimColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizing.sm),
          Text(
            'Your feedback helps us make managing your flat even better.',
            style: AppTypography.bodyM.copyWith(color: context.textSecColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizing.lg),
          AppButton(
            label: 'Yes, I love it!',
            onPressed: () => Navigator.of(context).pop(true),
            variant: AppButtonVariant.primary,
          ),
          const SizedBox(height: AppSizing.sm),
          AppButton(
            label: 'Not really',
            onPressed: () => Navigator.of(context).pop(false),
            variant: AppButtonVariant.text,
          ),
        ],
      ),
    );
  }
}

/// Invisible gate: schedules a single review check shortly after the screen it
/// wraps settles. Drop it around a calm, post-login surface (the main shell).
class ReviewPromptGate extends StatefulWidget {
  const ReviewPromptGate({super.key, required this.child});

  final Widget child;

  @override
  State<ReviewPromptGate> createState() => _ReviewPromptGateState();
}

class _ReviewPromptGateState extends State<ReviewPromptGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Let the screen settle so the prompt never lands mid-transition.
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) await ReviewPrompt.maybeAsk(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
