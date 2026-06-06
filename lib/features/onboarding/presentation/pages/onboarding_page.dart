import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/onboarding_service.dart';

// ── Slide model ───────────────────────────────────────────────────────────────

class _Slide {
  const _Slide({
    required this.icon,
    required this.headline,
    required this.body,
    required this.accentColor,
  });
  final IconData icon;
  final String headline;
  final String body;
  final Color accentColor;
}

const _slides = [
  _Slide(
    icon: Icons.home_rounded,
    headline: 'Your flat, organized.',
    body:
        'Manage your bachelor flat from one place — members, meals, expenses, and payments, always in sync.',
    accentColor: AppColors.brand,
  ),
  _Slide(
    icon: Icons.restaurant_rounded,
    headline: 'Meals, tracked daily.',
    body:
        'Log breakfast, lunch, and dinner. Points accumulate into a fair meal cost, calculated automatically for everyone.',
    accentColor: Color(0xFF10B981),
  ),
  _Slide(
    icon: Icons.receipt_long_rounded,
    headline: 'Expenses, split fairly.',
    body:
        'Record household costs, approve shared bills, and see exactly who paid what. No more confusion.',
    accentColor: Color(0xFFF59E0B),
  ),
  _Slide(
    icon: Icons.account_balance_wallet_rounded,
    headline: 'Settle up, every month.',
    body:
        'Deposit into your wallet, clear your contribution, and close the month with a full financial summary.',
    accentColor: AppColors.brandAccent,
  ),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  bool _navigating = false;

  Future<void> _finish() async {
    if (_navigating) return;
    _navigating = true;
    await OnboardingService.instance.markOnboardingSeen();
    if (mounted) context.go(AppRoutes.email);
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.bgColor;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ────────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: isLast ? 0.0 : 1.0,
                duration: 200.ms,
                child: TextButton(
                  onPressed: isLast ? null : _skip,
                  style: TextButton.styleFrom(
                    foregroundColor: context.textTerColor,
                    padding: const EdgeInsets.fromLTRB(
                        AppSizing.sp16, AppSizing.sp12, AppSizing.sp20, 0),
                    textStyle: AppTypography.labelM,
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),

            // ── Slides ─────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // ── Bottom area ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.pagePadding,
                AppSizing.sp8,
                AppSizing.pagePadding,
                AppSizing.sp32,
              ),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => _Dot(active: i == _page),
                    ),
                  ),
                  const SizedBox(height: AppSizing.sp24),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: AppSizing.buttonHeight,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizing.r16),
                        ),
                        textStyle: AppTypography.labelL,
                        elevation: 0,
                      ),
                      child: AnimatedSwitcher(
                        duration: 200.ms,
                        child: Text(
                          isLast ? 'Get Started' : 'Next',
                          key: ValueKey(isLast),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single slide ──────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.sp32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizing.r24),
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.18),
                width: AppSizing.borderWidthMd,
              ),
            ),
            child: Icon(
              slide.icon,
              size: 52,
              color: slide.accentColor,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.85, 0.85),
                duration: 420.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 300.ms),

          const SizedBox(height: AppSizing.sp32),

          // Headline
          Text(
            slide.headline,
            textAlign: TextAlign.center,
            style: AppTypography.displayM.copyWith(
              color: context.textPrimColor,
              height: 1.25,
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms, delay: 80.ms)
              .slideY(begin: 0.08, end: 0, duration: 350.ms, delay: 80.ms),

          const SizedBox(height: AppSizing.sp16),

          // Body
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyL.copyWith(
              color: context.textSecColor,
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms, delay: 140.ms)
              .slideY(begin: 0.08, end: 0, duration: 350.ms, delay: 140.ms),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ── Dot indicator ─────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 250.ms,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? AppColors.brand : context.borderColor,
        borderRadius: BorderRadius.circular(AppSizing.rFull),
      ),
    );
  }
}

