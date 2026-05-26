import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/env/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  final String email;
  const LoginPage({super.key, required this.email});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    _passwordCtrl.text = AppEnv.testPassword;
    super.initState();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthLoginRequested(
            email: widget.email,
            password: _passwordCtrl.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          AppSnackbar.error(context, state.message);
        }
        // AuthAuthenticated is handled by router redirect
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: Form(
                key: _formKey,
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
                        borderRadius:
                            BorderRadius.circular(AppSizing.radiusLg),
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
                      AppStrings.loginTitle,
                      style: AppTypography.h1,
                    ),
                    const SizedBox(height: AppSizing.xs),
                    Text(
                      'Enter your password',
                      style: AppTypography.bodyM
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizing.xs),
                    Text(
                      widget.email,
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSizing.xl),
                    // Password field with show/hide toggle
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(context),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Password is required' : null,
                      style: AppTypography.bodyL
                          .copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: AppStrings.passwordLabel,
                        hintText: AppStrings.passwordHint,
                        labelStyle: AppTypography.labelM
                            .copyWith(color: AppColors.textSecondary),
                        hintStyle: AppTypography.bodyM
                            .copyWith(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surface100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizing.md,
                          vertical: AppSizing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusLg),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusLg),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusLg),
                          borderSide: const BorderSide(
                              color: AppColors.brand,
                              width: AppSizing.borderWidthLg),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusLg),
                          borderSide:
                              const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusLg),
                          borderSide: const BorderSide(
                              color: AppColors.error,
                              width: AppSizing.borderWidthLg),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: AppSizing.iconMd,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizing.xs,
                              vertical: AppSizing.sp4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppStrings.forgotPassword,
                          style: AppTypography.bodyM.copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizing.lg),
                    // Gradient login button
                    _GradientButton(
                      label: AppStrings.loginLabel,
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
