import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
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
  String _selectedTimezone = 'Asia/Dhaka';

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
        timezone: _selectedTimezone,
      ),
    );
  }

  Future<void> _showTimezonePicker(BuildContext context) async {
    final allZones =
        tz.timeZoneDatabase.locations.keys.toList()..sort();
    final TextEditingController searchCtrl = TextEditingController();
    List<String> filtered = List.from(allZones);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizing.radiusLg),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: AppSizing.sm),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius:
                            BorderRadius.circular(AppSizing.radiusFull),
                      ),
                    ),
                    const SizedBox(height: AppSizing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      child: Text(
                        AppStrings.flatTimezonePickerTitle,
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    const SizedBox(height: AppSizing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.pagePadding,
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: AppStrings.flatTimezoneSearchHint,
                          hintStyle: AppTypography.bodySmall.copyWith(
                            color: context.textSecColor,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: context.textSecColor,
                          ),
                          filled: true,
                          fillColor: context.surfaceColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizing.radiusMd,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSizing.sp12,
                          ),
                        ),
                        onChanged: (query) {
                          setSheetState(() {
                            filtered = allZones
                                .where(
                                  (z) => z.toLowerCase().contains(
                                        query.toLowerCase(),
                                      ),
                                )
                                .toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizing.sm),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final zone = filtered[index];
                          final isSelected = zone == _selectedTimezone;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedTimezone = zone);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizing.pagePadding,
                                vertical: AppSizing.sp12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      zone,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: isSelected
                                            ? AppColors.brand
                                            : context.textPrimColor,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.brand,
                                      size: AppSizing.iconSm,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
    searchCtrl.dispose();
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
                    // Timezone picker tile
                    InkWell(
                      onTap: () => _showTimezonePicker(context),
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizing.md,
                          vertical: AppSizing.sp12,
                        ),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius:
                              BorderRadius.circular(AppSizing.radiusMd),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.language_rounded,
                              color: context.textSecColor,
                              size: AppSizing.iconMd,
                            ),
                            const SizedBox(width: AppSizing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.flatTimezoneLabel,
                                    style: AppTypography.labelS.copyWith(
                                      color: context.textSecColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedTimezone,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.textSecColor,
                              size: AppSizing.iconMd,
                            ),
                          ],
                        ),
                      ),
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
