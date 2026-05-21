import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../flat/domain/entities/flat_entity.dart';
import '../../../flat/domain/entities/flat_member_entity.dart';
import '../../../flat/presentation/bloc/flat_bloc.dart';
import '../args/settlement_page_args.dart';
import '../cubit/member_cubit.dart';
import '../widgets/member_card.dart';

class MemberListPage extends StatefulWidget {
  final FlatEntity flat;

  const MemberListPage({super.key, required this.flat});

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  @override
  void initState() {
    super.initState();
    context.read<MemberCubit>().load(widget.flat.id);
  }

  String? get _myUserId {
    final s = context.read<AuthBloc>().state;
    return s is AuthAuthenticated ? s.user.id : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MemberCubit, MemberState>(
      listener: _onStateChange,
      builder: (context, state) {
        if (state is MemberLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        List<FlatMemberEntity> members = [];
        Set<String> exitIds = const {};
        bool isActionLoading = false;

        if (state is MemberError) {
          // Initial load failed — show full-screen error with retry
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSizing.md),
                  TextButton(
                    onPressed: () =>
                        context.read<MemberCubit>().load(widget.flat.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is MemberLoaded) {
          members = state.members;
          exitIds = state.exitInProgressIds;
        } else if (state is MemberActionLoading) {
          members = state.members;
          exitIds = state.exitInProgressIds;
          isActionLoading = true;
        } else if (state is MemberSettlementReady) {
          members = state.members;
          exitIds = state.exitInProgressIds;
        } else if (state is MemberActionError) {
          // Action failed — keep list visible (snackbar shown by listener)
          members = state.members;
          exitIds = state.exitInProgressIds;
        }

        final myUserId = _myUserId;
        final myMember = myUserId != null
            ? members.where((m) => m.userId == myUserId).firstOrNull
            : null;
        final iAmManager = myMember?.isManager ?? false;
        final hasCoManager = members.any((m) => m.isCoManager);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    context.read<MemberCubit>().load(widget.flat.id),
                child: ListView(
                  padding: const EdgeInsets.all(AppSizing.pagePadding),
                  children: [
                    // Summary strip
                    _SummaryStrip(
                      memberCount: members.length,
                      totalExpenses: widget.flat.totalFixedExpenses,
                    ),
                    const SizedBox(height: AppSizing.md),
                    // Member cards
                    ...members.map((member) {
                      final isMe = member.userId == myUserId;
                      final hasExit = exitIds.contains(member.flatMemberId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizing.sm),
                        child: MemberCard(
                          member: member,
                          isMe: isMe,
                          hasExitInProgress: hasExit,
                          isManager: iAmManager,
                          hasCoManager: hasCoManager,
                          onChangeRole: iAmManager && !isMe
                              ? (role) =>
                                  _onChangeRole(context, member, role, hasCoManager)
                              : null,
                          onTransferManager: iAmManager && !isMe
                              ? () => _onTransferManager(context, member)
                              : null,
                          onInitiateExit: iAmManager && !isMe && !hasExit
                              ? () => _onInitiateExit(context, member)
                              : null,
                          onViewSettlement: hasExit && (iAmManager || isMe)
                              ? () => _onViewSettlement(context, member)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              if (isActionLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x26000000),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Members', style: AppTypography.titleLarge),
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
        ),
        onPressed: () => context.pop(),
      ),
    );
  }

  void _onStateChange(BuildContext context, MemberState state) {
    if (state is MemberActionError) {
      AppSnackbar.error(context, state.message);
    }
    if (state is MemberSettlementReady) {
      final myUserId = _myUserId;
      final members = state.members;
      final myMember = myUserId != null
          ? members.where((m) => m.userId == myUserId).firstOrNull
          : null;
      final iAmManager = myMember?.isManager ?? false;

      context.push(
        AppRoutes.flatSettlement,
        extra: SettlementPageArgs(
          flatId: widget.flat.id,
          memberId: state.memberId,
          settlement: state.settlement,
          isManager: iAmManager,
        ),
      ).then((_) {
        if (!context.mounted) return;
        context.read<MemberCubit>().acknowledgeSettlement();
        context.read<MemberCubit>().load(widget.flat.id);
        context.read<FlatBloc>().add(FlatRefreshRequested(widget.flat.id));
      });
    }
  }

  // ─── Action Handlers ──────────────────────────────────────────────────────

  Future<void> _onChangeRole(
    BuildContext context,
    FlatMemberEntity member,
    String newRole,
    bool hasCoManager,
  ) async {
    if (newRole == 'co-manager' && hasCoManager) {
      AppSnackbar.error(context, 'Demote the current co-manager first.');
      return;
    }
    final label = newRole == 'co-manager' ? 'Co-Manager' : 'Member';
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Change Role',
      message: 'Make ${member.name} a $label?',
      confirmLabel: 'Change',
    );
    if (confirmed != true || !context.mounted) return;
    context.read<MemberCubit>().changeRole(
      flatId: widget.flat.id,
      memberId: member.flatMemberId,
      role: newRole,
    );
    context.read<FlatBloc>().add(FlatRefreshRequested(widget.flat.id));
  }

  Future<void> _onTransferManager(
    BuildContext context,
    FlatMemberEntity member,
  ) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Transfer Manager Role',
      message:
          'You will become a regular member and ${member.name} will become the manager. '
          'This cannot be undone unless the new manager transfers the role back.',
      confirmLabel: 'Transfer',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    context.read<MemberCubit>().transferManager(
      flatId: widget.flat.id,
      newManagerId: member.flatMemberId,
    );
    context.read<FlatBloc>().add(FlatRefreshRequested(widget.flat.id));
  }

  Future<void> _onInitiateExit(
    BuildContext context,
    FlatMemberEntity member,
  ) async {
    final refundController = TextEditingController(text: '0');
    double fixedRefund = 0;

    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      title: 'Initiate Exit — ${member.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This will calculate ${member.name}\'s settlement. '
            'They will be restricted to payment actions only until exit is finalised or cancelled.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizing.md),
          AppTextField(
            controller: refundController,
            label: 'Refund from this month\'s fixed contribution (optional)',
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSizing.lg),
          AppButton(
            label: 'Calculate Settlement',
            onPressed: () {
              fixedRefund =
                  double.tryParse(refundController.text.trim()) ?? 0;
              Navigator.of(context).pop(true);
            },
          ),
          const SizedBox(height: AppSizing.sm),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    context.read<MemberCubit>().initiateExit(
      flatId: widget.flat.id,
      memberId: member.flatMemberId,
      fixedRefund: fixedRefund,
    );
  }

  void _onViewSettlement(BuildContext context, FlatMemberEntity member) {
    context.read<MemberCubit>().viewSettlement(
      flatId: widget.flat.id,
      memberId: member.flatMemberId,
    );
  }
}

// ─── Summary Strip ────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final int memberCount;
  final double totalExpenses;

  const _SummaryStrip({
    required this.memberCount,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: 'Total Members', value: '$memberCount'),
          Container(width: 1, height: 32, color: AppColors.border),
          _SummaryItem(
            label: 'Total Expenses',
            value: '৳${totalExpenses.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
        ),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
