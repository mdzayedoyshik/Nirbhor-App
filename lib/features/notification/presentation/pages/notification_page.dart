import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../complaint/presentation/args/complaint_page_args.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Notifications',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizing.xs),
                        Text(
                          'No new notifications right now.',
                          style: AppTypography.bodyM.copyWith(
                            color: AppColors.textSecondary,
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

    if (type.contains('complaint')) {
      context.push(
        AppRoutes.complaints,
        extra: ComplaintPageArgs(
          flatId: widget.args.flatId,
          canManage: widget.args.canManage,
          myMemberId: widget.args.myMemberId,
        ),
      );
    } else if (type.contains('task')) {
      // TaskPageArgs requires members list — navigate without members (empty)
      context.push(
        AppRoutes.tasks,
        extra: TaskPageArgs(
          flatId: widget.args.flatId,
          canManage: widget.args.canManage,
          myMemberId: widget.args.myMemberId,
          members: const [],
        ),
      );
    } else if (type.contains('payment') ||
        type.contains('wallet') ||
        type.contains('contribution')) {
      context.push(
        AppRoutes.walletHome,
        extra: WalletPageArgs(
          flatId: widget.args.flatId,
          canManage: widget.args.canManage,
        ),
      );
    }
    // other types: no navigation
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
          color: AppColors.textTertiary,
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
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizing.r12),
            boxShadow: AppColors.shadowSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                color: AppColors.textPrimary,
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
                                  color: AppColors.textSecondary,
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _timeAgo(notification.createdAt),
                            style: AppTypography.labelS.copyWith(
                              color: AppColors.textTertiary,
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
    if (t.contains('complaint')) {
      return _TypeInfo(Icons.report_problem_outlined, Colors.orange);
    }
    if (t.contains('task')) {
      return _TypeInfo(Icons.task_alt, Colors.blue);
    }
    if (t.contains('payment') ||
        t.contains('wallet') ||
        t.contains('contribution')) {
      return _TypeInfo(Icons.account_balance_wallet_outlined, Colors.green);
    }
    if (t.contains('member') ||
        t.contains('joined') ||
        t.contains('exit')) {
      return _TypeInfo(Icons.people_outline, Colors.purple);
    }
    return _TypeInfo(Icons.notifications_outlined, Colors.grey);
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
