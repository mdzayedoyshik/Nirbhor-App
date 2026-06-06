import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../args/otp_page_args.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context
          .read<AuthBloc>()
          .add(AuthForgotPasswordRequested(_emailCtrl.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthForgotPasswordOtpSent) {
          context.pushReplacement(
            AppRoutes.otp,
            extra: OtpPageArgs(
              otpVerificationToken: state.otpVerificationToken,
              email: state.email,
              hint: null, // null = forgot-password flow
            ),
          );
        } else if (state is AuthFailure) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.bgColor,
            elevation: 0,
            leading: BackButton(color: context.textPrimColor),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizing.md),
                    Text(AppStrings.forgotPasswordTitle,
                        style: AppTypography.headlineLarge),
                    const SizedBox(height: AppSizing.xs),
                    Text(
                      AppStrings.forgotPasswordSubtitle,
                      style: AppTypography.bodyMedium
                          .copyWith(color: context.textSecColor),
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
                        if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizing.xl),
                    AppButton(
                      label: AppStrings.sendResetCode,
                      loading: loading,
                      onPressed: () => _submit(context),
                    ),
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
