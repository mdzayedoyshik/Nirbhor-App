import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/auth_enums.dart';
import '../../../../core/env/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../args/otp_page_args.dart';
import '../bloc/auth_bloc.dart';

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  initState() {
    super.initState();
    _emailCtrl.text = AppEnv.testMail;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthEmailCheckRequested(_emailCtrl.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordRequired) {
          context.go(AppRoutes.login, extra: state.email);
        } else if (state is AuthOtpSent) {
          context.go(
            AppRoutes.otp,
            extra: OtpPageArgs(
              otpVerificationToken: state.otpVerificationToken,
              email: state.email,
              hint: state.hint,
            ),
          );
        } else if (state is AuthFailure) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final anyLoading = state is AuthLoading;
        final emailLoading =
            anyLoading && state.source == AuthLoadingSource.emailCheck;
        final googleLoading =
            anyLoading && state.source == AuthLoadingSource.google;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizing.xxl),

                    // ── Brand logo mark ───────────────────────────────────
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(AppSizing.r20),
                          boxShadow: AppColors.shadowBrand,
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: AppColors.white,
                          size: 44,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSizing.lg),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      'Welcome to Nirbhor',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSizing.xs),

                    // ── Subtitle ──────────────────────────────────────────
                    Text(
                      AppStrings.emailSubtitle,
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSizing.xl),

                    // ── Email field ───────────────────────────────────────
                    AppTextField(
                      controller: _emailCtrl,
                      label: AppStrings.emailLabel,
                      hint: AppStrings.emailHint,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(context),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!RegExp(
                          r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(v)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSizing.lg),

                    // ── Continue button (gradient wrapper) ────────────────
                    _GradientButton(
                      label: AppStrings.continueLabel,
                      loading: emailLoading,
                      disabled: anyLoading,
                      onPressed: () => _submit(context),
                    ),

                    const SizedBox(height: AppSizing.md),

                    // ── "or" divider ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.brand.withValues(alpha: 0.2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizing.sm,
                          ),
                          child: Text(
                            AppStrings.orDivider,
                            style: AppTypography.labelM.copyWith(
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.brand.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizing.md),

                    // ── Google button ─────────────────────────────────────
                    AppButton(
                      label: AppStrings.continueWithGoogle,
                      variant: AppButtonVariant.outlined,
                      loading: googleLoading,
                      icon: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        width: 20,
                        height: 20,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 22,
                          color: AppColors.brand,
                        ),
                      ),
                      onPressed: anyLoading
                          ? null
                          : () => context.read<AuthBloc>().add(
                              const AuthGoogleSignInRequested(),
                            ),
                    ),

                    const SizedBox(height: AppSizing.xxl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Gradient button ────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.disabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (loading || disabled) ? null : onPressed,
      child: AnimatedOpacity(
        opacity: disabled ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: AppSizing.buttonHeight,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppSizing.r16),
            boxShadow: AppColors.shadowMd,
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: AppSizing.spinnerSize,
                  height: AppSizing.spinnerSize,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizing.borderWidthLg,
                    color: AppColors.white,
                  ),
                )
              : Text(
                  label,
                  style: AppTypography.labelL.copyWith(
                    color: AppColors.white,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}
