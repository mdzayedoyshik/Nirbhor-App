import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../complaint/presentation/args/complaint_page_args.dart';
import '../../../expense/presentation/args/expense_list_args.dart';
import '../../../flat/presentation/bloc/flat_bloc.dart';
import '../../../summary/presentation/args/summary_page_args.dart';
import '../../../task/presentation/args/task_page_args.dart';
import '../../../wallet/presentation/args/wallet_page_args.dart';
import '../../domain/entities/notification_entity.dart';
import '../args/notification_page_args.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, required this.args});

  final NotificationPageArgs args;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context
          .read<NotificationBloc>()
          .add(const NotificationLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Notifications',
          style: AppTypography.h3.copyWith(color: context.textPrimColor),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int count = 0;
              if (state is NotificationListLoaded) count = state.unreadCount;
              if (state is NotificationError) count = state.unreadCount;
              if (count == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => context
                    .read<NotificationBloc>()
                    .add(const NotificationMarkAllReadRequested()),
                icon: const Icon(
                  Icons.done_all_rounded,
                  size: AppSizing.iconSm + 2,
                  color: AppColors.brand,
                ),
                label: Text(
                  'Mark all read',
                  style: AppTypography.labelM.copyWith(
                    color: AppColors.brand,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: AppSizing.xs),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationError) {
            AppSnackbar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is NotificationListLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            );
          }

          final notifications = switch (state) {
            NotificationListLoaded(notifications: final n) => n,
            NotificationError(notifications: final n) =>
              n ?? <NotificationEntity>[],
            _ => <NotificationEntity>[],
          };

          final isLoadingMore = state is NotificationListLoaded
              ? state.isLoadingMore
              : false;

          if (notifications.isEmpty && state is! NotificationListLoading) {
            return RefreshIndicator(
              color: AppColors.brand,
              onRefresh: () async {
                context
                    .read<NotificationBloc>()
                    .add(const NotificationLoadRequested());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 40,
                            color: AppColors.brand,
                          ),
                        ),
                        const SizedBox(height: AppSizing.md),
                        Text(
                          "You're all caught up",
                          style: AppTypography.h4.copyWith(
                            color: context.textPrimColor,
                          ),
                        ),
                        const SizedBox(height: AppSizing.xs),
                        Text(
                          'No new notifications right now.',
                          style: AppTypography.bodyM.copyWith(
                            color: context.textSecColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Split into Today / Earlier ───────────────────────────────────
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayItems = notifications
              .where((n) =>
                  (DateTime.tryParse(n.createdAt)?.toLocal() ?? now)
                      .isAfter(todayStart))
              .toList();
          final earlierItems = notifications
              .where((n) =>
                  !(DateTime.tryParse(n.createdAt)?.toLocal() ?? now)
                      .isAfter(todayStart))
              .toList();

          return RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () async {
              context
                  .read<NotificationBloc>()
                  .add(const NotificationLoadRequested());
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSizing.pagePadding),
              itemCount: _sectionItemCount(
                    todayItems,
                    earlierItems,
                  ) +
                  (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                final built = _buildSectionItem(
                  context,
                  index,
                  todayItems,
                  earlierItems,
                );
                if (built != null) return built;

                // Loading more indicator
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brand,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  int _sectionItemCount(
    List<NotificationEntity> today,
    List<NotificationEntity> earlier,
  ) {
    int count = 0;
    if (today.isNotEmpty) count += 1 + today.length; // header + items
    if (earlier.isNotEmpty) count += 1 + earlier.length;
    return count;
  }

  Widget? _buildSectionItem(
    BuildContext context,
    int index,
    List<NotificationEntity> today,
    List<NotificationEntity> earlier,
  ) {
    int cursor = 0;

    if (today.isNotEmpty) {
      if (index == cursor) return _SectionHeader(label: 'Today');
      cursor++;
      final localIndex = index - cursor;
      if (localIndex < today.length) {
        final n = today[localIndex];
        return _NotificationTile(
          notification: n,
          args: widget.args,
          onDismissed: () => context
              .read<NotificationBloc>()
              .add(NotificationDeleteRequested(n.id)),
          onTap: () => _handleTap(context, n),
        );
      }
      cursor += today.length;
    }

    if (earlier.isNotEmpty) {
      if (index == cursor) return _SectionHeader(label: 'Earlier');
      cursor++;
      final localIndex = index - cursor;
      if (localIndex < earlier.length) {
        final n = earlier[localIndex];
        return _NotificationTile(
          notification: n,
          args: widget.args,
          onDismissed: () => context
              .read<NotificationBloc>()
              .add(NotificationDeleteRequested(n.id)),
          onTap: () => _handleTap(context, n),
        );
      }
    }

    return null;
  }

  void _handleTap(BuildContext context, NotificationEntity n) {
    if (!n.isRead) {
      context
          .read<NotificationBloc>()
          .add(NotificationMarkReadRequested(n.id));
    }

    final type = n.type.toLowerCase();
    final flatId = widget.args.flatId;
    final canManage = widget.args.canManage;
    final myMemberId = widget.args.myMemberId;

    // ── Join requests ────────────────────────────────────────────────────────
    if (type.contains('join_request')) {
      // join_request_received  → manager sees pending requests list
      // join_request_declined  → non-manager; push-only, no in-app navigation
      if (canManage) {
        context.push(AppRoutes.flatRequests, extra: flatId);
      }
      return;
    }

    // ── New member joined ────────────────────────────────────────────────────
    if (type == 'member_joined') {
      // FlatBloc is a root-level singleton — always accessible.
      final raw = context.read<FlatBloc>().state;
      final resolved = raw is FlatActionLoading
          ? raw.base
          : raw is FlatError
              ? raw.fallback
              : raw;
      if (resolved is FlatLoaded) {
        context.push(AppRoutes.flatMembers, extra: resolved.flat);
      }
      return;
    }

    // ── Exit initiated (received by the exiting member) ──────────────────────
    if (type.contains('exit')) {
      // Home will automatically render PendingExitPage when FlatState is
      // FlatPendingExit — no need to construct SettlementPageArgs here.
      context.go(AppRoutes.home);
      return;
    }

    // ── Tasks ────────────────────────────────────────────────────────────────
    if (type.contains('task')) {
      context.push(
        AppRoutes.tasks,
        extra: TaskPageArgs(
          flatId: flatId,
          canManage: canManage,
          myMemberId: myMemberId,
          members: const [],
        ),
      );
      return;
    }

    // ── Complaints ───────────────────────────────────────────────────────────
    if (type.contains('complaint')) {
      context.push(
        AppRoutes.complaints,
        extra: ComplaintPageArgs(
          flatId: flatId,
          canManage: canManage,
          myMemberId: myMemberId,
        ),
      );
      return;
    }

    // ── Wallet / payments ────────────────────────────────────────────────────
    if (type.contains('payment') ||
        type.contains('wallet') ||
        type.contains('contribution')) {
      // payment_submitted      → Awaiting tab (tab 1) — manager verifies
      // payment_request_received → Pending tab (tab 0) — member pays
      // payment_verified / payment_rejected / contribution → wallet home
      if (type == 'payment_submitted') {
        context.push(
          AppRoutes.walletRequests,
          extra: WalletPageArgs(flatId: flatId, canManage: canManage, initialTab: 1),
        );
      } else if (type == 'payment_request_received') {
        context.push(
          AppRoutes.walletRequests,
          extra: WalletPageArgs(flatId: flatId, canManage: canManage),
        );
      } else {
        // payment_verified, payment_rejected, fixed_contribution_deducted
        context.push(
          AppRoutes.walletHome,
          extra: WalletPageArgs(flatId: flatId, canManage: canManage),
        );
      }
      return;
    }

    // ── Expense approved ─────────────────────────────────────────────────────
    if (type.contains('expense')) {
      context.push(
        AppRoutes.expenses,
        extra: ExpenseListArgs(flatId: flatId, canManage: canManage),
      );
      return;
    }

    // ── Month closed → summary ───────────────────────────────────────────────
    if (type.contains('month_closed') || type.contains('monthly')) {
      context.push(
        AppRoutes.summary,
        extra: SummaryPageArgs(
          flatId: flatId,
          isManager: canManage,
          myMemberId: myMemberId,
        ),
      );
      return;
    }
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizing.pagePadding,
        AppSizing.md,
        AppSizing.pagePadding,
        AppSizing.sp8,
      ),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(
          color: context.textTerColor,
        ),
      ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.args,
    required this.onDismissed,
    required this.onTap,
  });

  final NotificationEntity notification;
  final NotificationPageArgs args;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final typeInfo = _iconForType(notification.type);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizing.pagePadding),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizing.r12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.white,
          size: 26,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSizing.sp12,
            vertical: AppSizing.sp4,
          ),
          decoration: BoxDecoration(
            color: isUnread
                ? AppColors.brand.withValues(alpha: 0.05)
                : context.cardColor,
            borderRadius: BorderRadius.circular(AppSizing.r12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Colored left border (unread indicator) ────────────────
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isUnread ? AppColors.brand : AppColors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSizing.r12),
                    bottomLeft: Radius.circular(AppSizing.r12),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizing.sp12,
                    vertical: AppSizing.sp12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leading icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: typeInfo.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          typeInfo.icon,
                          color: typeInfo.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSizing.sp12),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: AppTypography.labelM.copyWith(
                                color: context.textPrimColor,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                            if (notification.message != null &&
                                notification.message!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                notification.message!,
                                style: AppTypography.bodyS.copyWith(
                                  color: context.textSecColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSizing.sp8),

                      // Trailing: time + unread dot
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _timeAgo(notification.createdAt),
                            style: AppTypography.labelS.copyWith(
                              color: context.textTerColor,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TypeInfo _iconForType(String type) {
    final t = type.toLowerCase();
    // Payment / wallet
    if (t.contains('payment_request_received') || t.contains('payment_request')) {
      return _TypeInfo(Icons.request_quote_outlined, const Color(0xFFFF9800)); // orange
    }
    if (t.contains('payment_submitted')) {
      return _TypeInfo(Icons.upload_rounded, const Color(0xFF2196F3)); // blue
    }
    if (t.contains('payment_verified')) {
      return _TypeInfo(Icons.verified_outlined, const Color(0xFF4CAF50)); // green
    }
    if (t.contains('payment_rejected')) {
      return _TypeInfo(Icons.cancel_outlined, const Color(0xFFF44336)); // red
    }
    if (t.contains('payment') || t.contains('wallet')) {
      return _TypeInfo(Icons.account_balance_wallet_outlined, const Color(0xFF2196F3));
    }
    if (t.contains('contribution') || t.contains('fixed')) {
      return _TypeInfo(Icons.calendar_month_outlined, const Color(0xFF009688)); // teal
    }
    // Tasks
    if (t.contains('task_assigned') || t.contains('task_created')) {
      return _TypeInfo(Icons.assignment_outlined, const Color(0xFF3F51B5)); // indigo
    }
    if (t.contains('task_completed')) {
      return _TypeInfo(Icons.task_alt, const Color(0xFF4CAF50));
    }
    if (t.contains('task')) {
      return _TypeInfo(Icons.task_alt, const Color(0xFF3F51B5));
    }
    // Complaints
    if (t.contains('complaint_resolved')) {
      return _TypeInfo(Icons.check_circle_outline, const Color(0xFF4CAF50));
    }
    if (t.contains('complaint')) {
      return _TypeInfo(Icons.report_problem_outlined, const Color(0xFFFF9800));
    }
    // Join / members
    if (t.contains('join_request_received')) {
      return _TypeInfo(Icons.person_add_outlined, const Color(0xFF9C27B0)); // purple
    }
    if (t.contains('join_request_approved') || t.contains('approved')) {
      return _TypeInfo(Icons.how_to_reg_outlined, const Color(0xFF4CAF50));
    }
    if (t.contains('join_request_rejected') || t.contains('declined')) {
      return _TypeInfo(Icons.person_remove_outlined, const Color(0xFFF44336));
    }
    if (t.contains('member') || t.contains('joined')) {
      return _TypeInfo(Icons.people_outline, const Color(0xFF9C27B0));
    }
    if (t.contains('exit')) {
      return _TypeInfo(Icons.exit_to_app_rounded, const Color(0xFFFF5722)); // deep orange
    }
    // Default
    return _TypeInfo(Icons.notifications_outlined, const Color(0xFF607D8B)); // blue grey
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal() ?? DateTime.now();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }
}

class _TypeInfo {
  const _TypeInfo(this.icon, this.color);
  final IconData icon;
  final Color color;
}
