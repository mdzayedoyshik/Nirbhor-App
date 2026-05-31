import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../args/reset_password_page_args.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';

class ResetPasswordPage extends StatefulWidget {
  final ResetPasswordPageArgs args;
  const ResetPasswordPage({super.key, required this.args});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthResetPasswordRequested(
            setupToken: widget.args.setupToken,
            newPassword: _passwordCtrl.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSuccess) {
          AppSnackbar.success(context, 'Password updated. Please log in.');
          context.go(AppRoutes.email);
        } else if (state is AuthFailure) {
          AppSnackbar.error(context, state.message);
        }
        // AuthAuthenticated (set_password flow) handled by router redirect
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        final title = widget.args.isSetPassword
            ? AppStrings.setPasswordTitle
            : AppStrings.resetPasswordTitle;

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.bgColor,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: AppTypography.headlineLarge),
                    const SizedBox(height: AppSizing.xs),
                    Text(
                      AppStrings.newPasswordHint,
                      style: AppTypography.bodyMedium
                          .copyWith(color: context.textSecColor),
                    ),
                    const SizedBox(height: AppSizing.xl),
                    AppTextField(
                      controller: _passwordCtrl,
                      label: AppStrings.newPasswordLabel,
                      hint: AppStrings.newPasswordHint,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(context),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizing.xl),
                    AppButton(
                      label: AppStrings.resetPasswordLabel,
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
