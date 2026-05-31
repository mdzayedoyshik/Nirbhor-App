import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/profile_bloc.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileBloc>().add(
        ProfilePasswordChangeRequested(
          oldPassword: _oldCtrl.text,
          newPassword: _newCtrl.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (_, curr) =>
          curr is ProfilePasswordChangeSuccess || curr is ProfileActionError,
      listener: (context, state) {
        if (state is ProfilePasswordChangeSuccess) {
          AppSnackbar.success(context, 'Password changed successfully');
          Navigator.of(context).pop();
        } else if (state is ProfileActionError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final loading =
            state is ProfileLoading || state is ProfileActionLoading;
        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.cardColor,
            elevation: 0,
            leading: BackButton(color: context.textPrimColor),
            title: Text(
              AppStrings.changePasswordTitle,
              style: AppTypography.titleLarge,
            ),
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
                    AppTextField(
                      controller: _oldCtrl,
                      label: AppStrings.oldPasswordLabel,
                      hint: AppStrings.passwordHint,
                      obscure: true,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Current password is required'
                          : null,
                    ),
                    const SizedBox(height: AppSizing.md),
                    AppTextField(
                      controller: _newCtrl,
                      label: AppStrings.newPasswordLabel,
                      hint: AppStrings.newPasswordHint,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(context),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'New password is required';
                        }
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizing.xl),
                    AppButton(
                      label: AppStrings.saveChanges,
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
