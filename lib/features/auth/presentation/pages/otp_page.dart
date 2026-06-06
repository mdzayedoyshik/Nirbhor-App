import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../args/complete_setup_page_args.dart';
import '../args/otp_page_args.dart';
import '../args/reset_password_page_args.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../bloc/auth_bloc.dart';

class OtpPage extends StatefulWidget {
  final OtpPageArgs args;
  const OtpPage({super.key, required this.args});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  static const int _resendCooldown = 30;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    for (final f in _focusNodes) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onFieldChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _startResendCooldown() {
    setState(() => _secondsLeft = _resendCooldown);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _submit(BuildContext context) {
    if (_otp.length != 6) {
      AppSnackbar.error(context, 'Please enter the 6-digit code');
      return;
    }
    context.read<AuthBloc>().add(AuthOtpSubmitted(
          otpVerificationToken: widget.args.otpVerificationToken,
          otp: _otp,
          hint: widget.args.hint,
          email: widget.args.email,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSetupReady) {
          context.go(
            AppRoutes.completeSetup,
            extra: CompleteSetupPageArgs(
              setupToken: state.setupToken,
              email: state.email,
            ),
          );
        } else if (state is AuthSetPasswordReady) {
          context.go(
            AppRoutes.resetPassword,
            extra: ResetPasswordPageArgs(
              setupToken: state.setupToken,
              isSetPassword: true,
            ),
          );
        } else if (state is AuthPasswordResetReady) {
          // forgot-password flow — keep email screen in the back-stack
          // so the user can try a different email if they need to
          context.pushReplacement(
            AppRoutes.resetPassword,
            extra: ResetPasswordPageArgs(setupToken: state.setupToken),
          );
        } else if (state is AuthFailure) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: BackButton(color: context.textPrimColor),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizing.md),
                  // Logo mark
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                      boxShadow: AppColors.shadowMd,
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: AppColors.white,
                      size: AppSizing.iconLg,
                    ),
                  ),
                  const SizedBox(height: AppSizing.lg),
                  Text(
                    AppStrings.verifyEmailTitle,
                    style: AppTypography.h1,
                  ),
                  const SizedBox(height: AppSizing.xs),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.bodyM
                          .copyWith(color: context.textSecColor),
                      children: [
                        const TextSpan(text: 'We sent a 6-digit code to '),
                        TextSpan(
                          text: widget.args.email,
                          style: AppTypography.bodyM.copyWith(
                            color: context.textPrimColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizing.xl),
                  _OtpBoxesRow(
                    controllers: _controllers,
                    focusNodes: _focusNodes,
                    onChanged: _onFieldChanged,
                  ),
                  const SizedBox(height: AppSizing.xl),
                  // Gradient confirm button
                  _GradientButton(
                    label: AppStrings.verifyLabel,
                    loading: loading,
                    onPressed: () => _submit(context),
                  ),
                  const SizedBox(height: AppSizing.md),
                  Center(
                    child: _secondsLeft > 0
                        ? Text(
                            'Resend code in ${_secondsLeft}s',
                            style: AppTypography.bodyM
                                .copyWith(color: context.textSecColor),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.didntReceiveCode,
                                style: AppTypography.bodyM
                                    .copyWith(color: context.textSecColor),
                              ),
                              TextButton(
                                onPressed: loading
                                    ? null
                                    : () {
                                        _startResendCooldown();
                                        final hint = widget.args.hint;
                                        if (hint != null) {
                                          context.read<AuthBloc>().add(
                                                AuthEmailCheckRequested(
                                                    widget.args.email),
                                              );
                                        }
                                      },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizing.xs),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppStrings.resendCode,
                                  style: AppTypography.bodyM.copyWith(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── OTP Boxes ─────────────────────────────────────────────────────────────────

class _OtpBoxesRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String, int) onChanged;

  const _OtpBoxesRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: AppTypography.h3.copyWith(
              color: context.textPrimColor,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: context.surfaceColor,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide: const BorderSide(
                    color: AppColors.brand, width: AppSizing.borderWidthLg),
              ),
            ),
            onChanged: (v) => onChanged(v, i),
          ),
        );
      }),
    );
  }
}

// ── Gradient Button ───────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizing.buttonHeight,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        boxShadow: AppColors.shadowMd,
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: AppSizing.spinnerSize,
                    height: AppSizing.spinnerSize,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: AppTypography.labelL.copyWith(
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
