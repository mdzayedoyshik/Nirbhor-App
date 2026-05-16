import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizing.dart';
import '../constants/app_typography.dart';
import 'app_button.dart';

class AppInputDialog extends StatefulWidget {
  final String title;
  final String label;
  final String? hint;
  final String? initialValue;
  final TextInputType keyboardType;
  final String confirmLabel;
  final String cancelLabel;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const AppInputDialog({
    super.key,
    required this.title,
    required this.label,
    this.hint,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.validator,
    this.inputFormatters,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String label,
    String? hint,
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => AppInputDialog(
        title: title,
        label: label,
        hint: hint,
        initialValue: initialValue,
        keyboardType: keyboardType,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        validator: validator,
        inputFormatters: inputFormatters,
      ),
    );
  }

  @override
  State<AppInputDialog> createState() => _AppInputDialogState();
}

class _AppInputDialogState extends State<AppInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      title: Text(widget.title, style: AppTypography.headlineSmall),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: AppTypography.labelLarge),
            const SizedBox(height: AppSizing.xs),
            TextFormField(
              controller: _controller,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              autofocus: true,
              validator: widget.validator,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.md,
                  vertical: AppSizing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: AppSizing.borderWidthMd,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: widget.cancelLabel,
          variant: AppButtonVariant.text,
          fullWidth: false,
          height: AppSizing.buttonHeightSm,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: widget.confirmLabel,
          variant: AppButtonVariant.primary,
          fullWidth: false,
          height: AppSizing.buttonHeightSm,
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
        ),
      ],
    );
  }
}
