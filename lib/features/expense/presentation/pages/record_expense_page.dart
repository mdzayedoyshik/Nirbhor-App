import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../bloc/expense_bloc.dart';

class RecordExpensePage extends StatefulWidget {
  const RecordExpensePage({
    super.key,
    required this.flatId,
    required this.memberCount,
    required this.canManage,
  });

  final String flatId;
  final int memberCount;
  final bool canManage;

  @override
  State<RecordExpensePage> createState() => _RecordExpensePageState();
}

class _RecordExpensePageState extends State<RecordExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'meal';
  DateTime _selectedDate = DateTime.now();

  static const Color _mealColor = Color(0xFFF57C00);
  static const Color _householdColor = Color(0xFF7B1FA2);
  static const Color _fixedColor = Color(0xFF1565C0);

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color get _activeColor {
    switch (_category) {
      case 'meal':
        return _mealColor;
      case 'household':
        return _householdColor;
      case 'fixed':
        return _fixedColor;
      default:
        return AppColors.primary;
    }
  }

  String get _categoryHint {
    if (!widget.canManage) {
      // Regular member — expense goes to manager for approval
      switch (_category) {
        case 'meal':
          return 'Your expense will be submitted for manager approval. Once approved, it will be deducted from the flat wallet.';
        case 'household':
          return 'Your expense will be submitted for manager approval. Once approved, it will be split equally among ${widget.memberCount} active members.';
        case 'fixed':
          return 'Your expense will be submitted for manager approval. Once approved, it will be deducted from the flat wallet.';
        default:
          return '';
      }
    }
    // Manager / co-manager — auto-approved immediately
    switch (_category) {
      case 'meal':
        return 'This expense will be immediately deducted from the flat wallet and the meal cost will be calculated per person.';
      case 'household':
        return 'This expense will be split equally among all ${widget.memberCount} active members and deducted from the flat wallet.';
      case 'fixed':
        return 'This is a fixed/one-time expense. It will be deducted from the flat wallet.';
      default:
        return '';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: AppColors.isDark(ctx)
              ? const ColorScheme.dark(primary: AppColors.primary)
              : const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    context.read<ExpenseBloc>().add(
          ExpenseRecordRequested(
            flatId: widget.flatId,
            amount: amount,
            category: _category,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            date: dateStr,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseError) {
          AppSnackbar.error(context, state.message);
        }
        if (state is ExpenseActionSuccess) {
          AppSnackbar.success(context, state.message);
          context.pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is ExpenseActionLoading;
        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.bgColor,
            elevation: 0,
            title: Text(AppStrings.recordExpenseTitle,
                style: AppTypography.headlineMedium),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              children: [
                // Category selector
                Text(AppStrings.categoryLabel,
                    style: AppTypography.titleMedium),
                const SizedBox(height: AppSizing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      _CategoryTab(
                        label: 'Meal',
                        value: 'meal',
                        selectedValue: _category,
                        color: _mealColor,
                        icon: Icons.restaurant_outlined,
                        onTap: () => setState(() => _category = 'meal'),
                      ),
                      _CategoryTab(
                        label: 'Household',
                        value: 'household',
                        selectedValue: _category,
                        color: _householdColor,
                        icon: Icons.home_outlined,
                        onTap: () => setState(() => _category = 'household'),
                      ),
                      _CategoryTab(
                        label: 'Fixed',
                        value: 'fixed',
                        selectedValue: _category,
                        color: _fixedColor,
                        icon: Icons.receipt_long_outlined,
                        onTap: () => setState(() => _category = 'fixed'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizing.sm),

                // Contextual hint
                Container(
                  padding: const EdgeInsets.all(AppSizing.sm),
                  decoration: BoxDecoration(
                    color: _activeColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    border: Border.all(
                        color: _activeColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: _activeColor, size: 16),
                      const SizedBox(width: AppSizing.xs),
                      Expanded(
                        child: Text(
                          _categoryHint,
                          style: AppTypography.bodySmall
                              .copyWith(color: _activeColor),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizing.lg),

                // Amount field
                Text(AppStrings.amountLabel,
                    style: AppTypography.titleMedium),
                const SizedBox(height: AppSizing.sm),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    hintText: AppStrings.amountHint,
                    prefixText: '৳ ',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Amount is required';
                    final n = double.tryParse(val);
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),

                const SizedBox(height: AppSizing.lg),

                // Description field
                Text(AppStrings.descriptionLabel,
                    style: AppTypography.titleMedium),
                const SizedBox(height: AppSizing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: AppStrings.descriptionHint,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusMd),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusMd),
                      borderSide:
                          const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),

                const SizedBox(height: AppSizing.lg),

                // Date picker
                Text('Date', style: AppTypography.titleMedium),
                const SizedBox(height: AppSizing.sm),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.md,
                      vertical: AppSizing.md,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius:
                          BorderRadius.circular(AppSizing.radiusMd),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            color: context.textSecColor, size: 20),
                        const SizedBox(width: AppSizing.sm),
                        Text(
                          _formatDate(_selectedDate),
                          style: AppTypography.bodyMedium,
                        ),
                        const Spacer(),
                        Icon(Icons.edit_outlined,
                            color: context.textSecColor, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSizing.xl),

                AppButton(
                  label: widget.canManage
                      ? AppStrings.recordExpenseLabel
                      : 'Submit for Approval',
                  loading: isLoading,
                  onPressed: isLoading ? null : _submit,
                  offlineDisabled: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final String selectedValue;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSizing.sm),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : context.textSecColor,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? color : context.textSecColor,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
