import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../auth/auth_controller.dart';
import '../notifications/notification_providers.dart';
import '../projects/project_providers.dart';
import '../providers.dart';
import '../tasks/task_card.dart';
import '../tasks/task_providers.dart';
import '../widgets/common.dart';
import '../widgets/offline_banner.dart';
import '../widgets/state_views.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final dashboard = ref.watch(dashboardProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(ref.watch(clockProvider)()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(session.name.split(' ').first),
          ],
        ),
        actions: [
          _NotificationButton(unreadCount: unread),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(cachedAt: ref.watch(tasksCachedAtProvider)),
          Expanded(
            child: dashboard.when(
              loading: () => const _DashboardSkeleton(),
              error: (error, _) => ErrorStateView(
                message: messageFor(error),
                onRetry: () => ref.invalidate(dashboardProvider),
              ),
              data: (data) => _DashboardBody(data: data),
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectsProvider);
        ref.invalidate(tasksProvider);
        await ref.read(dashboardProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _OrgCard(orgName: session.orgName, role: session.role),
          const SizedBox(height: AppSpacing.lg),

          _StatsGrid(data: data),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(
            title: 'Assigned to you',
            action: TextButton(
              onPressed: () => context.go(Routes.tasks),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (data.myOpenTasks.isEmpty)
            const _InlineEmpty(
              icon: Icons.inbox_outlined,
              message: 'Nothing assigned to you right now.',
            )
          else
            for (final task in data.myOpenTasks)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: TaskCard(
                  task: task,
                  onTap: () => context.push(Routes.task(task.id)),
                ),
              ),

          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Recent projects',
            action: TextButton(
              onPressed: () => context.go(Routes.projects),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (data.projects.isEmpty)
            const _InlineEmpty(
              icon: Icons.folder_outlined,
              message: 'No projects yet. Create one to get started.',
            )
          else
            for (final project in data.projects.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _MiniProjectCard(project: project),
              ),

          const SizedBox(height: AppSpacing.lg),
          _QuickActions(hasProjects: data.projects.isNotEmpty),
        ],
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  const _OrgCard({required this.orgName, required this.role});

  final String orgName;
  final OrgRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: AppRadius.field,
              ),
              child: Icon(
                Icons.apartment,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orgName,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four summary tiles. Uses a fixed two-column grid rather than a Row so the
/// labels wrap instead of overflowing on small screens.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final stats = data.stats;
    final tiles = [
      (
        label: 'Projects',
        value: '${data.projectCount}',
        color: AppColors.primaryBlue,
        icon: Icons.folder_outlined,
      ),
      (
        label: 'Open tasks',
        value: '${stats.open}',
        color: AppColors.warning,
        icon: Icons.pending_actions,
      ),
      (
        label: 'Completed',
        value: '${stats.completed}',
        color: AppColors.success,
        icon: Icons.task_alt,
      ),
      (
        label: 'Overdue',
        value: '${stats.overdue}',
        color: AppColors.error,
        icon: Icons.event_busy,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        final spacing = AppSpacing.md;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: _StatTile(
                  label: tile.label,
                  value: tile.value,
                  color: tile.color,
                  icon: tile.icon,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).c.wash(color),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniProjectCard extends StatelessWidget {
  const _MiniProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: () => context.push(Routes.project(project.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Plurals.countLabel(project.taskCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.hasProjects});

  final bool hasProjects;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Quick actions'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(Routes.newProject()),
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: const Text('New project'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: hasProjects
                    ? () => context.push(Routes.newTask())
                    : null,
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('New task'),
              ),
            ),
          ],
        ),
        if (!hasProjects)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Create a project before adding tasks.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(Routes.notifications),
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.notifications_none),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SkeletonBox(width: double.infinity, height: 72),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 104)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: SkeletonBox(height: 104)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: const [
            Expanded(child: SkeletonBox(height: 104)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: SkeletonBox(height: 104)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SkeletonBox(width: 140, height: 16),
        const SizedBox(height: AppSpacing.md),
        const SkeletonBox(width: double.infinity, height: 92),
        const SizedBox(height: AppSpacing.md),
        const SkeletonBox(width: double.infinity, height: 92),
      ],
    );
  }
}
