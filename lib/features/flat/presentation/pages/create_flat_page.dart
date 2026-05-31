import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_image_picker.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/flat_bloc.dart';

class CreateFlatPage extends StatefulWidget {
  const CreateFlatPage({super.key});

  @override
  State<CreateFlatPage> createState() => _CreateFlatPageState();
}

class _CreateFlatPageState extends State<CreateFlatPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _photoUrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<FlatBloc>().add(
      FlatCreateRequested(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        photoUrl: _photoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlatBloc, FlatState>(
      listener: (context, state) {
        if (state is FlatLoaded) {
          AppSnackbar.success(context, AppStrings.flatCreatedSuccess);
          context.go(AppRoutes.home);
        } else if (state is FlatError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading =
            state is FlatActionLoading &&
            state.source == FlatLoadingSource.create;

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            title: Text(
              AppStrings.createFlatTitle,
              style: AppTypography.titleLarge,
            ),
            backgroundColor: context.cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: context.textPrimColor,
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
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.apartment_rounded,
                            color: AppColors.white,
                            size: AppSizing.iconLg,
                          ),
                          const SizedBox(height: AppSizing.sm),
                          Text(
                            'Create Your Flat',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: AppSizing.xs),
                          Text(
                            'Set up your flat and invite members using a join code.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizing.xl),
                    AppTextField(
                      controller: _nameCtrl,
                      label: AppStrings.flatNameLabel,
                      hint: AppStrings.flatNameHint,
                      prefixIcon: Icon(
                        Icons.apartment_outlined,
                        color: context.textSecColor,
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
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: context.textSecColor,
                      ),
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSizing.md),
                    AppImagePicker(
                      imageUrl: _photoUrl,
                      circular: false,
                      size: 160,
                      onUploaded: (url) => setState(() => _photoUrl = url),
                    ),
                    const SizedBox(height: AppSizing.xl),
                    AppButton(
                      label: AppStrings.createFlatLabel,
                      loading: isLoading,
                      onPressed: isLoading ? null : () => _submit(context),
                      icon: const Icon(Icons.add, color: AppColors.white),
                    ),
                    const SizedBox(height: AppSizing.md),
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
