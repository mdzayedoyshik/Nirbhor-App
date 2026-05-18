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
                    Text(
                      AppStrings.welcomeTitle,
                      style: AppTypography.displayLarge,
                    ),
                    const SizedBox(height: AppSizing.xs),
                    Text(
                      AppStrings.emailSubtitle,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizing.xl),
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
                    AppButton(
                      label: AppStrings.continueLabel,
                      loading: emailLoading,
                      onPressed: anyLoading ? null : () => _submit(context),
                    ),
                    const SizedBox(height: AppSizing.md),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizing.sm,
                          ),
                          child: Text(
                            AppStrings.orDivider,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: AppSizing.md),
                    AppButton(
                      label: AppStrings.continueWithGoogle,
                      variant: AppButtonVariant.outlined,
                      loading: googleLoading,
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
