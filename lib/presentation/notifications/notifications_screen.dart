import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../providers.dart';
import '../widgets/state_views.dart';
import 'notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final hasUnread = ref.watch(unreadNotificationCountProvider) > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () => ref
                  .read(notificationControllerProvider.notifier)
                  .markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const SkeletonList(itemHeight: 76),
        error: (error, _) => ErrorStateView(
          message: messageFor(error),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications',
                message:
                    'When someone assigns you a task, it will show up here.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notificationsProvider);
                  await ref.read(notificationsProvider.future);
                },
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _NotificationTile(notification: items[index]),
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();

    return ListTile(
      onTap: () {
        if (!notification.read) {
          ref
              .read(notificationControllerProvider.notifier)
              .markRead(notification.id);
        }
        final taskId = notification.taskId;
        if (taskId != null) context.push(Routes.task(taskId));
      },
      leading: CircleAvatar(
        backgroundColor: notification.read
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.assignment_ind_outlined,
          size: 20,
          color: notification.read
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        notification.message,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: notification.read ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      subtitle: Text(Dates.timeAgo(notification.createdAt, now)),
      trailing: notification.read
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
