import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/feedback_bloc.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const _types = [
    _FeedbackType(value: 'bug', label: 'Bug Report', emoji: '🐛'),
    _FeedbackType(value: 'feature', label: 'Feature Request', emoji: '✨'),
    _FeedbackType(value: 'general', label: 'General', emoji: '💬'),
  ];

  String _selectedType = 'bug';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<FeedbackBloc>().add(
          FeedbackSubmitRequested(
            type: _selectedType,
            title: _titleCtrl.text.trim().isEmpty
                ? null
                : _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedbackBloc, FeedbackState>(
      listenWhen: (_, curr) =>
          curr is FeedbackSuccess || curr is FeedbackError,
      listener: (context, state) {
        if (state is FeedbackSuccess) {
          AppSnackbar.success(context, 'Thank you for your feedback!');
          Navigator.pop(context);
        } else if (state is FeedbackError) {
          AppSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is FeedbackLoading;
        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(
            backgroundColor: context.cardColor,
            elevation: 0,
            leading: BackButton(color: context.textPrimColor),
            title: Text(
              'Report / Feedback',
              style: AppTypography.titleLarge,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizing.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizing.sm),

                  // ── Type selector ──────────────────────────────────────────
                  _SectionLabel(label: 'Type'),
                  const SizedBox(height: AppSizing.sm),
                  Row(
                    children: _types.map((t) {
                      final selected = _selectedType == t.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: t == _types.last ? 0 : AppSizing.xs,
                          ),
                          child: _TypeChip(
                            type: t,
                            selected: selected,
                            onTap: () =>
                                setState(() => _selectedType = t.value),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizing.lg),

                  // ── Title ──────────────────────────────────────────────────
                  _SectionLabel(label: 'Details'),
                  const SizedBox(height: AppSizing.sm),
                  AppTextField(
                    controller: _titleCtrl,
                    label: 'Title (optional)',
                    hint: 'Brief summary…',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSizing.sm),

                  // ── Description ────────────────────────────────────────────
                  AppTextField(
                    controller: _descCtrl,
                    label: 'Description',
                    hint: 'Describe the bug or feature in detail…',
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Description is required';
                      }
                      if (v.trim().length < 10) {
                        return 'Please provide at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizing.xl),

                  // ── Submit button ──────────────────────────────────────────
                  AppButton(
                    label: 'Submit',
                    loading: isLoading,
                    onPressed: () => _submit(context),
                  ),
                  const SizedBox(height: AppSizing.md),
                ],
              ),
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

// ── Feedback Type ─────────────────────────────────────────────────────────────

class _FeedbackType {
  final String value;
  final String label;
  final String emoji;

  const _FeedbackType({
    required this.value,
    required this.label,
    required this.emoji,
  });
}

// ── Type Chip ─────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final _FeedbackType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.sm,
          vertical: AppSizing.sp12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand.withValues(alpha: 0.1)
              : context.cardColor,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.brand : context.borderColor,
            width: selected
                ? AppSizing.borderWidthMd
                : AppSizing.borderWidth,
          ),
          boxShadow: selected ? AppColors.shadowSm : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: AppSizing.xs),
            Text(
              type.label,
              style: AppTypography.labelS.copyWith(
                color: selected ? AppColors.brand : context.textSecColor,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
