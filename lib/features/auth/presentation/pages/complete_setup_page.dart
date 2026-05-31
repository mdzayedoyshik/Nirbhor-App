import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../args/complete_setup_page_args.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';

class CompleteSetupPage extends StatefulWidget {
  final CompleteSetupPageArgs args;
  const CompleteSetupPage({super.key, required this.args});

  @override
  State<CompleteSetupPage> createState() => _CompleteSetupPageState();
}

class _CompleteSetupPageState extends State<CompleteSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthCompleteSetupRequested(
            setupToken: widget.args.setupToken,
            name: _nameCtrl.text.trim(),
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
        // AuthAuthenticated handled by router redirect
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
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
                    Text(AppStrings.createAccountTitle,
                        style: AppTypography.headlineLarge),
                    const SizedBox(height: AppSizing.xs),
                    Text(
                      widget.args.email,
                      style: AppTypography.bodyMedium
                          .copyWith(color: context.textSecColor),
                    ),
                    const SizedBox(height: AppSizing.xl),
                    AppTextField(
                      controller: _nameCtrl,
                      label: AppStrings.nameLabel,
                      hint: AppStrings.nameHint,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: AppSizing.md),
                    AppTextField(
                      controller: _passwordCtrl,
                      label: AppStrings.createPasswordLabel,
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
                      label: AppStrings.createAccountLabel,
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
