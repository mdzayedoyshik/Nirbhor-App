import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_image_picker.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';

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
    context.read<ProfileBloc>().add(const ProfileFetchRequested());
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
      context.read<ProfileBloc>().add(
        ProfileUpdateRequested(name: _nameCtrl.text.trim()),
      );
    }
  }

  /// Returns up to 2 uppercase initials from the name.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (_, curr) =>
          curr is ProfileUpdateSuccess ||
          curr is ProfileActionError ||
          curr is ProfileLoadError,
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          setState(() => _editing = false);
          AppSnackbar.success(context, 'Profile updated');
        } else if (state is ProfileActionError) {
          AppSnackbar.error(context, state.message);
        } else if (state is ProfileLoadError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileLoading;
        final isActionLoading = state is ProfileActionLoading;

        final user = switch (state) {
          ProfileLoaded s => s.user,
          ProfileActionLoading s => s.user,
          ProfileUpdateSuccess s => s.user,
          ProfileActionError s => s.user,
          _ => null,
        };

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.cardColor,
            elevation: 0,
            leading: BackButton(color: context.textPrimColor),
            title: Text(
              AppStrings.profileTitle,
              style: AppTypography.titleLarge,
            ),
            actions: [
              if (user != null && !_editing)
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: context.textPrimColor,
                  ),
                  onPressed: () => _startEdit(user.name),
                ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : user == null
              ? const Center(child: Text('Failed to load profile'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSizing.lg),
                      // ── Profile Header ────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            // Avatar: use image picker if available, otherwise gradient initials
                            user.avatarUrl != null
                                ? AppImagePicker(
                                    imageUrl: user.avatarUrl,
                                    name: user.name,
                                    size: AppSizing.avatar80,
                                    onUploaded: (url) {
                                      context.read<ProfileBloc>().add(
                                        ProfileUpdateRequested(
                                          name: user.name,
                                          avatarUrl: url,
                                        ),
                                      );
                                    },
                                  )
                                : GestureDetector(
                                    onTap: () {},
                                    child: Container(
                                      width: AppSizing.avatar80,
                                      height: AppSizing.avatar80,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.brandGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: AppColors.shadowMd,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _initials(user.name),
                                          style: AppTypography.h2.copyWith(
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: AppSizing.md),
                            Text(
                              user.name,
                              style: AppTypography.h2,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSizing.xs),
                            Text(
                              user.email,
                              style: AppTypography.bodyM
                                  .copyWith(color: context.textSecColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizing.xl),

                      if (_editing) ...[
                        // ── Edit Form ─────────────────────────────────────
                        Form(
                          key: _formKey,
                          child: AppTextField(
                            controller: _nameCtrl,
                            label: AppStrings.nameLabel,
                            hint: AppStrings.nameHint,
                            textInputAction: TextInputAction.done,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppSizing.lg),
                        AppButton(
                          label: AppStrings.saveChanges,
                          loading: isActionLoading,
                          onPressed: () => _saveEdit(context),
                        ),
                        const SizedBox(height: AppSizing.sm),
                        AppButton(
                          label: AppStrings.cancel,
                          variant: AppButtonVariant.text,
                          onPressed: () => setState(() => _editing = false),
                        ),
                      ] else ...[
                        // ── Account Section ────────────────────────────────
                        _SectionLabel(label: 'Account'),
                        const SizedBox(height: AppSizing.sm),
                        _SettingsCard(
                          children: [
                            _SettingsRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Name',
                              value: user.name,
                            ),
                            _SettingsDivider(),
                            _SettingsRow(
                              icon: Icons.mail_outline_rounded,
                              label: 'Email',
                              value: user.email,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizing.lg),
                        // ── Security Section ───────────────────────────────
                        _SectionLabel(label: 'Security'),
                        const SizedBox(height: AppSizing.sm),
                        _SettingsCard(
                          children: [
                            _SettingsRow(
                              icon: Icons.lock_outline_rounded,
                              label: user.hasPassword
                                  ? AppStrings.changePasswordTitle
                                  : 'Set Password',
                              showArrow: true,
                              onTap: () => context.push(
                                user.hasPassword
                                    ? AppRoutes.changePassword
                                    : AppRoutes.setPassword,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizing.lg),
                        // ── Preferences Section ────────────────────────────
                        _SectionLabel(label: 'Preferences'),
                        const SizedBox(height: AppSizing.sm),
                        _SettingsCard(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizing.md,
                                vertical: AppSizing.sp12,
                              ),
                              child: Row(
                                children: [
                                  Builder(
                                    builder: (ctx) => Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: ctx.surfaceColor,
                                        borderRadius: BorderRadius.circular(
                                            AppSizing.radiusSm),
                                      ),
                                      child: const Icon(
                                        Icons.palette_outlined,
                                        color: AppColors.brand,
                                        size: AppSizing.iconMd,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSizing.md),
                                  Expanded(
                                    child: Text(
                                      'Theme',
                                      style: AppTypography.labelM,
                                    ),
                                  ),
                                  const _ThemeToggle(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizing.xl),
                        // ── Support Section ────────────────────────────────
                        _SectionLabel(label: 'Support'),
                        const SizedBox(height: AppSizing.sm),
                        _SettingsCard(
                          children: [
                            _SettingsRow(
                              icon: Icons.help_outline_rounded,
                              label: 'Help & FAQ',
                              showArrow: true,
                              onTap: () => context.push(AppRoutes.helpCenter),
                            ),
                            _SettingsDivider(),
                            _SettingsRow(
                              icon: Icons.feedback_outlined,
                              label: 'Report / Feedback',
                              showArrow: true,
                              onTap: () => context.push(AppRoutes.feedback),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizing.xl),
                        // ── Logout ─────────────────────────────────────────
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
                      const SizedBox(height: AppSizing.xl),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizing.xs),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.overline.copyWith(
          color: context.textTerColor,
        ),
      ),
    );
  }
}

// ── Settings Card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        boxShadow: AppColors.shadowSm,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(children: children),
    );
  }
}

// ── Settings Row ──────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool showArrow;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.md,
            vertical: AppSizing.sp12,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(AppSizing.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: AppColors.brand,
                  size: AppSizing.iconMd,
                ),
              ),
              const SizedBox(width: AppSizing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.labelM),
                    if (value != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        value!,
                        style: AppTypography.bodyS.copyWith(
                          color: context.textSecColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showArrow)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: AppSizing.iconMd,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings Divider ──────────────────────────────────────────────────────────

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.borderColor,
      indent: AppSizing.md + 36 + AppSizing.md,
    );
  }
}

// ── Theme Toggle (3-way pill segmented) ───────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final current = themeState.mode;
        return Container(
          height: 34,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemePill(
                icon: Icons.light_mode_rounded,
                label: 'Light',
                selected: current == ThemeMode.light,
                onTap: () =>
                    context.read<ThemeCubit>().setTheme(ThemeMode.light),
              ),
              _ThemePill(
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                selected: current == ThemeMode.dark,
                onTap: () =>
                    context.read<ThemeCubit>().setTheme(ThemeMode.dark),
              ),
              _ThemePill(
                icon: Icons.settings_brightness_rounded,
                label: 'Auto',
                selected: current == ThemeMode.system,
                onTap: () =>
                    context.read<ThemeCubit>().setTheme(ThemeMode.system),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.sp8,
          vertical: AppSizing.sp4,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          borderRadius: BorderRadius.circular(AppSizing.radiusFull),
          boxShadow: selected ? AppColors.shadowSm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppColors.white : context.textSecColor,
            ),
            const SizedBox(width: AppSizing.sp4),
            Text(
              label,
              style: AppTypography.labelS.copyWith(
                color: selected ? AppColors.white : context.textSecColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
