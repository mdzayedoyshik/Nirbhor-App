import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
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

  static const _minDelay = Duration(milliseconds: 2200);
  static const _animDuration = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();

    // Force status bar to be transparent on the splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
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

    Future.delayed(_minDelay, () {
      if (!mounted) return;
      _minDelayDone = true;
      _tryNavigate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auth may have already resolved before the BlocListener fires.
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
    if (!mounted || !_minDelayDone || _resolvedState == null) return;
    if (_resolvedState is AuthAuthenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.email);
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (_, state) => _onAuthState(state),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              // ── centre content ────────────────────────────────────────
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      FadeTransition(
                        opacity: _opacity,
                        child: ScaleTransition(
                          scale: _scale,
                          child: Image.asset(
                            'assets/images/icon.png',
                            width: 112,
                            height: 112,
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
                            style: AppTypography.headlineLarge.copyWith(
                              color: AppColors.textPrimary,
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
                            'Live together, hassle-free',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
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
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
