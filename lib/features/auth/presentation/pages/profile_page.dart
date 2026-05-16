import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_image_picker.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/profile_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _startEdit(String name) {
    _nameCtrl.text = name;
    setState(() => _editing = true);
  }

  void _saveEdit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileCubit>().updateProfile(name: _nameCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdated) {
          setState(() => _editing = false);
          AppSnackbar.success(context, 'Profile updated');
        } else if (state is ProfileFailure) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final loading = state is ProfileLoading;
        final user = state is ProfileLoaded
            ? state.user
            : state is ProfileUpdated
            ? state.user
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: BackButton(color: AppColors.textPrimary),
            title: Text(
              AppStrings.profileTitle,
              style: AppTypography.titleLarge,
            ),
            actions: [
              if (user != null && !_editing)
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => _startEdit(user.name),
                ),
            ],
          ),
          body: loading && user == null
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? const Center(child: Text('Failed to load profile'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSizing.md),
                      Center(
                        child: AppImagePicker(
                          imageUrl: user.avatarUrl,
                          name: user.name,
                          size: AppSizing.avatarRadius * 2,
                          onUploaded: (url) {
                            context.read<ProfileCubit>().updateProfile(
                              name: user.name,
                              avatarUrl: url,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSizing.md),
                      if (_editing) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _nameCtrl,
                                label: AppStrings.nameLabel,
                                hint: AppStrings.nameHint,
                                textInputAction: TextInputAction.done,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizing.lg),
                        AppButton(
                          label: AppStrings.saveChanges,
                          loading: loading,
                          onPressed: () => _saveEdit(context),
                        ),
                        const SizedBox(height: AppSizing.sm),
                        AppButton(
                          label: AppStrings.cancel,
                          variant: AppButtonVariant.text,
                          onPressed: () => setState(() => _editing = false),
                        ),
                      ] else ...[
                        _InfoTile(label: 'Name', value: user.name),
                        _InfoTile(label: 'Email', value: user.email),
                        const SizedBox(height: AppSizing.xl),
                        AppButton(
                          label: AppStrings.changePasswordTitle,
                          variant: AppButtonVariant.outlined,
                          onPressed: () =>
                              context.push(AppRoutes.changePassword),
                        ),
                        const SizedBox(height: AppSizing.md),
                        AppButton(
                          label: AppStrings.logoutLabel,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            final confirmed = await AppDialog.confirm(
                              context: context,
                              title: AppStrings.confirmLogoutTitle,
                              message: AppStrings.confirmLogoutMessage,
                              confirmLabel: AppStrings.logoutLabel,
                              destructive: true,
                            );
                            if (confirmed == true && context.mounted) {
                              context.read<AuthBloc>().add(
                                const AuthLogoutRequested(),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ── Info tile ──────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizing.md,
        horizontal: AppSizing.md,
      ),
      margin: const EdgeInsets.only(bottom: AppSizing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: AppSizing.xs),
          Text(value, style: AppTypography.bodyLarge),
        ],
      ),
    );
  }
}
