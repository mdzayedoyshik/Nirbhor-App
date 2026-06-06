import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/onboarding_service.dart';
import '../bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // ── animation ─────────────────────────────────────────────────────────────
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _nameSlide;

  // ── navigation state ──────────────────────────────────────────────────────
  bool _minDelayDone = false;
  AuthState? _resolvedState;
  bool? _hasSeenOnboarding;

  static const _minDelay = Duration(milliseconds: 2200);
  static const _animDuration = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _ctrl = AnimationController(vsync: this, duration: _animDuration);

    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _scale = Tween<double>(
      begin: 0.70,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));

    _nameSlide = Tween<double>(
      begin: 24,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    // Load first-launch flag in parallel with the min delay.
    OnboardingService.instance.hasSeenOnboarding().then((seen) {
      if (!mounted) return;
      _hasSeenOnboarding = seen;
      _tryNavigate();
    });

    Future.delayed(_minDelay, () {
      if (!mounted) return;
      _minDelayDone = true;
      _tryNavigate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated || state is AuthUnauthenticated) {
      _resolvedState = state;
    }
  }

  void _onAuthState(AuthState state) {
    if (state is AuthAuthenticated || state is AuthUnauthenticated) {
      _resolvedState = state;
      _tryNavigate();
    }
  }

  void _tryNavigate() {
    if (!mounted) return;
    // All three signals must be ready before navigating.
    if (!_minDelayDone || _resolvedState == null || _hasSeenOnboarding == null) return;

    if (_resolvedState is AuthAuthenticated) {
      context.go(AppRoutes.home);
    } else if (_hasSeenOnboarding!) {
      context.go(AppRoutes.email);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg = context.bgColor;
    final isDark = context.isDarkMode;

    return BlocListener<AuthBloc, AuthState>(
      listener: (_, state) => _onAuthState(state),
      child: Scaffold(
        backgroundColor: bg,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: bg,
          child: SafeArea(
            child: Column(
              children: [
                // ── centre content ────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo mark
                        FadeTransition(
                          opacity: _opacity,
                          child: ScaleTransition(
                            scale: _scale,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.brand.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(
                                  AppSizing.radiusLg,
                                ),
                                border: Border.all(
                                  color:
                                      AppColors.brand.withValues(alpha: 0.18),
                                  width: AppSizing.borderWidthMd,
                                ),
                              ),
                              child: const Icon(
                                Icons.home_rounded,
                                size: 44,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // App name
                        FadeTransition(
                          opacity: _opacity,
                          child: AnimatedBuilder(
                            animation: _nameSlide,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _nameSlide.value),
                              child: child,
                            ),
                            child: Text(
                              'Nirbhor',
                              style: AppTypography.h1.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tagline
                        FadeTransition(
                          opacity: _opacity,
                          child: AnimatedBuilder(
                            animation: _nameSlide,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _nameSlide.value),
                              child: child,
                            ),
                            child: Text(
                              'নির্ভর — Your Home, Together',
                              style: AppTypography.bodyM.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── bottom loader ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: FadeTransition(
                    opacity: _opacity,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
