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
import '../../domain/entities/flat_entity.dart';
import '../bloc/flat_bloc.dart';

class FlatSettingsPage extends StatefulWidget {
  final FlatEntity flat;

  const FlatSettingsPage({super.key, required this.flat});

  @override
  State<FlatSettingsPage> createState() => _FlatSettingsPageState();
}

class _FlatSettingsPageState extends State<FlatSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.flat.name);
    _addressCtrl = TextEditingController(text: widget.flat.address ?? '');
    _photoUrl = widget.flat.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<FlatBloc>().add(
      FlatUpdateRequested(
        flatId: widget.flat.id,
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        photoUrl: _photoUrl,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: AppStrings.deleteFlatConfirmTitle,
      message: AppStrings.deleteFlatConfirmMsg,
      confirmLabel: AppStrings.deleteFlatLabel,
      destructive: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<FlatBloc>().add(FlatDeleteRequested(widget.flat.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlatBloc, FlatState>(
      listener: (context, state) {
        if (state is FlatLoaded) {
          AppSnackbar.success(context, AppStrings.flatUpdatedMsg);
          context.pop();
        } else if (state is FlatNone) {
          AppSnackbar.success(context, AppStrings.flatDeletedMsg);
          context.go(AppRoutes.home);
        } else if (state is FlatError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isUpdating =
            state is FlatActionLoading &&
            state.source == FlatLoadingSource.update;
        final isDeleting =
            state is FlatActionLoading &&
            state.source == FlatLoadingSource.delete;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              AppStrings.flatSettingsTitle,
              style: AppTypography.titleLarge,
            ),
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizing.sm),
                    AppTextField(
                      controller: _nameCtrl,
                      label: AppStrings.flatNameLabel,
                      hint: AppStrings.flatNameHint,
                      prefixIcon: const Icon(
                        Icons.apartment_outlined,
                        color: AppColors.textSecondary,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Flat name is required'
                          : null,
                    ),
                    const SizedBox(height: AppSizing.md),
                    AppTextField(
                      controller: _addressCtrl,
                      label: AppStrings.flatAddressLabel,
                      hint: AppStrings.flatAddressHint,
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textSecondary,
                      ),
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSizing.md),
                    Text(
                      AppStrings.flatPhotoUrlLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizing.sm),
                    AppImagePicker(
                      imageUrl: _photoUrl,
                      circular: false,
                      size: 160,
                      onUploaded: (url) => setState(() => _photoUrl = url),
                    ),
                    const SizedBox(height: AppSizing.xl),
                    AppButton(
                      label: AppStrings.updateFlatLabel,
                      loading: isUpdating,
                      onPressed: (isUpdating || isDeleting)
                          ? null
                          : () => _submit(context),
                    ),
                    const SizedBox(height: AppSizing.xxl),
                    // Danger zone
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizing.md),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.error,
                                size: AppSizing.iconSm + 4,
                              ),
                              const SizedBox(width: AppSizing.xs),
                              Text(
                                'Danger Zone',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizing.sm),
                          Text(
                            AppStrings.deleteFlatConfirmMsg,
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: AppSizing.md),
                          AppButton(
                            label: AppStrings.deleteFlatLabel,
                            variant: AppButtonVariant.outlined,
                            loading: isDeleting,
                            onPressed: (isUpdating || isDeleting)
                                ? null
                                : () => _confirmDelete(context),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
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
