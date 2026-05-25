import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Text(
          'Notifications',
          style: AppTypography.titleLarge.copyWith(color: AppColors.white),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int count = 0;
              if (state is NotificationListLoaded) count = state.unreadCount;
              if (state is NotificationError) count = state.unreadCount;
              if (count == 0) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.done_all, color: AppColors.white),
                tooltip: 'Mark all read',
                onPressed: () => context
                    .read<NotificationBloc>()
                    .add(const NotificationMarkAllReadRequested()),
              );
            },
          ),
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
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final notifications = switch (state) {
            NotificationListLoaded(notifications: final n) => n,
            NotificationError(notifications: final n) => n ?? <NotificationEntity>[],
            _ => <NotificationEntity>[],
          };

          final isLoadingMore = state is NotificationListLoaded
              ? state.isLoadingMore
              : false;

          if (notifications.isEmpty && state is! NotificationListLoading) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context
                    .read<NotificationBloc>()
                    .add(const NotificationLoadRequested());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: AppTypography.bodyMedium.copyWith(
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

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context
                  .read<NotificationBloc>()
                  .add(const NotificationLoadRequested());
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  args: widget.args,
                  onDismissed: () => context
                      .read<NotificationBloc>()
                      .add(NotificationDeleteRequested(notification.id)),
                  onTap: () => _handleTap(context, notification),
                );
              },
            ),
          );
        },
      ),
    );
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
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Icon(typeInfo.icon, color: typeInfo.color, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (notification.message != null &&
                        notification.message!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.message!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Trailing: time + unread dot
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _timeAgo(notification.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF), // AppColors.primary
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
