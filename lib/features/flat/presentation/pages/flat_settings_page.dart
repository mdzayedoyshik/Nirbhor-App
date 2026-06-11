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
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../audit_log/presentation/args/audit_log_page_args.dart';
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
  late String _selectedTimezone;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.flat.name);
    _addressCtrl = TextEditingController(text: widget.flat.address ?? '');
    _selectedTimezone = widget.flat.timezone;
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
      listenWhen: (previous, current) {
        if (previous is FlatActionLoading &&
            previous.source == FlatLoadingSource.update) {
          return current is FlatLoaded || current is FlatError;
        }
        if (previous is FlatActionLoading &&
            previous.source == FlatLoadingSource.delete) {
          return current is FlatNone || current is FlatError;
        }
        return false;
      },
      listener: (context, state) {
        if (state is FlatLoaded) {
          AppSnackbar.success(context, AppStrings.flatUpdatedMsg);
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
          backgroundColor: context.bgColor,
          appBar: AppBar(
            title: Text(
              AppStrings.flatSettingsTitle,
              style: AppTypography.headlineMedium,
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
                    // const SizedBox(height: AppSizing.sm),

                    // // ── Preferences (Theme) ──────────────────────────────────
                    // _SectionLabel(label: 'Preferences'),
                    // const SizedBox(height: AppSizing.sm),
                    // _SettingsCard(
                    //   children: [
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: AppSizing.md,
                    //         vertical: AppSizing.sp12,
                    //       ),
                    //       child: Row(
                    //         children: [
                    //           Container(
                    //             width: 36,
                    //             height: 36,
                    //             decoration: BoxDecoration(
                    //               color: AppColors.surface100,
                    //               borderRadius: BorderRadius.circular(
                    //                   AppSizing.radiusSm),
                    //             ),
                    //             child: const Icon(
                    //               Icons.palette_outlined,
                    //               color: AppColors.brand,
                    //               size: AppSizing.iconMd,
                    //             ),
                    //           ),
                    //           const SizedBox(width: AppSizing.md),
                    //           Expanded(
                    //             child: Text(
                    //               'Theme',
                    //               style: AppTypography.labelM,
                    //             ),
                    //           ),
                    //           const _ThemeToggle(),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: AppSizing.lg),

                    // // ── Flat Details ─────────────────────────────────────────
                    // _SectionLabel(label: 'Flat Details'),
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
                      label: AppStrings.updateFlatLabel,
                      loading: isUpdating,
                      onPressed: (isUpdating || isDeleting)
                          ? null
                          : () => _submit(context),
                    ),
                    const SizedBox(height: AppSizing.xxl),

                    // ── Activity Section ─────────────────────────────────────
                    _SectionLabel(label: 'Activity'),
                    const SizedBox(height: AppSizing.sm),
                    _SettingsCard(
                      children: [
                        Material(
                          color: AppColors.transparent,
                          child: InkWell(
                            onTap: () => context.push(
                              AppRoutes.auditLog,
                              extra: AuditLogPageArgs(flatId: widget.flat.id, members: widget.flat.members),
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizing.radiusLg,
                            ),
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
                                      borderRadius: BorderRadius.circular(
                                        AppSizing.radiusSm,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.history_rounded,
                                      color: AppColors.brand,
                                      size: AppSizing.iconMd,
                                    ),
                                  ),
                                  const SizedBox(width: AppSizing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Audit Log',
                                          style: AppTypography.labelM,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'View all changes in this flat',
                                          style: AppTypography.bodyS.copyWith(
                                            color: context.textSecColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textTertiary,
                                    size: AppSizing.iconMd,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizing.lg),

                    // ── Danger Zone ──────────────────────────────────────────
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
                    const SizedBox(height: AppSizing.xl),
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

// ── Theme Toggle (3-way pill segmented) ──────────────────────────────────────

// class _ThemeToggle extends StatelessWidget {
//   const _ThemeToggle();

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ThemeCubit, ThemeState>(
//       builder: (context, themeState) {
//         final current = themeState.mode;
//         return Container(
//           height: 34,
//           decoration: BoxDecoration(
//             color: AppColors.surface200,
//             borderRadius: BorderRadius.circular(AppSizing.radiusFull),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _ThemePill(
//                 icon: Icons.light_mode_rounded,
//                 label: 'Light',
//                 selected: current == ThemeMode.light,
//                 onTap: () => context
//                     .read<ThemeCubit>()
//                     .setTheme(ThemeMode.light),
//               ),
//               _ThemePill(
//                 icon: Icons.dark_mode_rounded,
//                 label: 'Dark',
//                 selected: current == ThemeMode.dark,
//                 onTap: () => context
//                     .read<ThemeCubit>()
//                     .setTheme(ThemeMode.dark),
//               ),
//               _ThemePill(
//                 icon: Icons.settings_brightness_rounded,
//                 label: 'System',
//                 selected: current == ThemeMode.system,
//                 onTap: () => context
//                     .read<ThemeCubit>()
//                     .setTheme(ThemeMode.system),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _ThemePill extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;

//   const _ThemePill({
//     required this.icon,
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(
//           horizontal: AppSizing.sp8,
//           vertical: AppSizing.sp4,
//         ),
//         decoration: BoxDecoration(
//           gradient: selected ? AppColors.brandGradient : null,
//           borderRadius: BorderRadius.circular(AppSizing.radiusFull),
//           boxShadow: selected ? AppColors.shadowSm : null,
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               size: 14,
//               color: selected ? AppColors.white : AppColors.textSecondary,
//             ),
//             const SizedBox(width: AppSizing.sp4),
//             Text(
//               label,
//               style: AppTypography.labelS.copyWith(
//                 color: selected ? AppColors.white : AppColors.textSecondary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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
        style: AppTypography.overline.copyWith(color: context.textTerColor),
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
