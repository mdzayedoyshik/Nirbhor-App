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
import '../../../../core/widgets/app_button.dart';
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

  @override
  void dispose() {
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
          context.go(
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: BackButton(color: AppColors.textPrimary),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizing.md),
                  Text(AppStrings.verifyEmailTitle,
                      style: AppTypography.headlineLarge),
                  const SizedBox(height: AppSizing.sm),
                  Text(
                    '${AppStrings.otpSentPrefix}${widget.args.email}',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizing.xl),
                  _OtpBoxesRow(
                    controllers: _controllers,
                    focusNodes: _focusNodes,
                    onChanged: _onFieldChanged,
                  ),
                  const SizedBox(height: AppSizing.xl),
                  AppButton(
                    label: AppStrings.verifyLabel,
                    loading: loading,
                    onPressed: () => _submit(context),
                  ),
                  const SizedBox(height: AppSizing.md),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppStrings.didntReceiveCode,
                            style: AppTypography.bodySmall),
                        GestureDetector(
                          onTap: loading
                              ? null
                              : () {
                                  final hint = widget.args.hint;
                                  if (hint == null) {
                                    // forgot password - resend not implemented; user goes back
                                  } else {
                                    // re-check email to re-send OTP
                                    context.read<AuthBloc>().add(
                                          AuthEmailCheckRequested(
                                              widget.args.email),
                                        );
                                  }
                                },
                          child: Text(
                            AppStrings.resendCode,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
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
          width: AppSizing.otpFieldWidth,
          height: AppSizing.otpFieldHeight,
          child: TextField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: AppTypography.headlineSmall,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (v) => onChanged(v, i),
          ),
        );
      }),
    );
  }
}
