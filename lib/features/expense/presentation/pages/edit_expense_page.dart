import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/expense_bloc.dart';

class EditExpensePage extends StatefulWidget {
  const EditExpensePage({
    super.key,
    required this.flatId,
    required this.expense,
  });

  final String flatId;
  final ExpenseEntity expense;

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;

  static const Color _mealColor = Color(0xFFF57C00);
  static const Color _householdColor = Color(0xFF7B1FA2);
  static const Color _fixedColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.expense.amount.toStringAsFixed(0));
    _descriptionController =
        TextEditingController(text: widget.expense.description ?? '');
    try {
      _selectedDate = DateTime.parse(widget.expense.date);
    } catch (_) {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color get _categoryColor {
    switch (widget.expense.expenseCategory) {
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

  String get _categoryLabel {
    switch (widget.expense.expenseCategory) {
      case 'meal':
        return 'Meal';
      case 'household':
        return 'Household';
      case 'fixed':
        return 'Fixed';
      default:
        return widget.expense.expenseCategory;
    }
  }

  IconData get _categoryIcon {
    switch (widget.expense.expenseCategory) {
      case 'meal':
        return Icons.restaurant_outlined;
      case 'household':
        return Icons.home_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
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
          ExpenseUpdateRequested(
            flatId: widget.flatId,
            expenseId: widget.expense.id,
            amount: amount,
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
            title: Text(AppStrings.editExpenseTitle,
                style: AppTypography.headlineMedium),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSizing.pagePadding),
              children: [
                // Category (read-only)
                Text(AppStrings.categoryLabel,
                    style: AppTypography.titleMedium),
                const SizedBox(height: AppSizing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.md,
                    vertical: AppSizing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                    border: Border.all(
                        color: _categoryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_categoryIcon,
                          color: _categoryColor, size: 20),
                      const SizedBox(width: AppSizing.sm),
                      Text(
                        _categoryLabel,
                        style: AppTypography.titleMedium
                            .copyWith(color: _categoryColor),
                      ),
                      const Spacer(),
                      Icon(Icons.lock_outline,
                          size: 14, color: context.textSecColor),
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
                  label: AppStrings.saveChanges,
                  loading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
