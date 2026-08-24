import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/permissions.dart';
import '../auth/auth_controller.dart';
import '../providers.dart';
import '../tasks/task_card.dart';
import '../tasks/task_providers.dart';
import '../tasks/task_status_sheet.dart';
import '../widgets/common.dart';
import '../widgets/app_illustrations.dart';
import '../widgets/state_views.dart';
import 'project_controller.dart';
import 'project_providers.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectByIdProvider(projectId));
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.valueOrNull?.name ?? 'Project'),
        actions: [
          if (project.hasValue)
            PopupMenuButton<_ProjectAction>(
              onSelected: (action) =>
                  _onAction(context, ref, action, project.requireValue),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _ProjectAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit project'),
                  ),
                ),
                if (Permissions.canDeleteProject(session))
                  PopupMenuItem(
                    value: _ProjectAction.delete,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Delete project',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      floatingActionButton: project.hasValue
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push(Routes.newTask(projectId: projectId)),
              icon: const Icon(Icons.add_task),
              label: const Text('Add task'),
            )
          : null,
      body: project.when(
        loading: () => const LoadingView(message: 'Loading project…'),
        error: (error, _) => ErrorStateView(
          message: messageFor(error),
          onRetry: () => ref.invalidate(projectByIdProvider(projectId)),
        ),
        data: (data) => _ProjectBody(project: data),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _ProjectAction action,
    Project project,
  ) async {
    switch (action) {
      case _ProjectAction.edit:
        context.push(Routes.editProject(project.id));
      case _ProjectAction.delete:
        final confirmed = await confirmAction(
          context,
          title: 'Delete project?',
          message:
              '"${project.name}" and its ${Plurals.count(project.taskCount, 'task')} '
              'will be permanently removed. This cannot be undone.',
        );
        if (!confirmed || !context.mounted) return;

        final result = await ref
            .read(projectControllerProvider.notifier)
            .delete(project.id);
        if (!context.mounted) return;

        if (result.isSuccess) {
          showAppSnackBar(context, 'Project deleted.');
          context.go(Routes.projects);
        } else {
          showAppSnackBar(context, result.errorOrNull!, isError: true);
        }
    }
  }
}

enum _ProjectAction { edit, delete }

class _ProjectBody extends ConsumerWidget {
  const _ProjectBody({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(projectTasksProvider(project.id));
    final now = ref.watch(clockProvider)();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectByIdProvider(project.id));
        ref.invalidate(projectTasksProvider(project.id));
        await ref.read(projectTasksProvider(project.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl * 2.5,
        ),
        children: [
          _ProjectSummary(project: project),
          const SizedBox(height: AppSpacing.lg),

          tasks.when(
            loading: () => const _StatsSkeleton(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) =>
                _TaskStatistics(stats: TaskStats.from(items, now)),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(
            title: 'Tasks',
            action: TextButton(
              onPressed: () => context.push(
                Routes.newTask(projectId: project.id),
              ),
              child: const Text('Add'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          tasks.when(
            loading: () => Column(
              children: const [
                SkeletonBox(width: double.infinity, height: 96),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(width: double.infinity, height: 96),
              ],
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: ErrorStateView(
                message: messageFor(error),
                onRetry: () =>
                    ref.invalidate(projectTasksProvider(project.id)),
              ),
            ),
            data: (items) => items.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: EmptyState(
                        art: AppArt.tasks,
                        title: 'No tasks yet',
                        message: 'Add the first task to get this project moving.',
                        actionLabel: 'Add a task',
                        onAction: () => context.push(
                          Routes.newTask(projectId: project.id),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final task in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: TaskCard(
                            task: task,
                            onTap: () => context.push(Routes.task(task.id)),
                            onStatusTap: () => showTaskStatusSheet(
                              context,
                              ref,
                              task,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProjectSummary extends StatelessWidget {
  const _ProjectSummary({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.name, style: theme.textTheme.titleMedium),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(project.description, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                TagChip(
                  label: project.status.label,
                  icon: Icons.circle,
                  tone: project.status.color(theme),
                  dense: true,
                ),
                TagChip(
                  label: 'Created ${Dates.full(project.createdAt)}',
                  icon: Icons.event_outlined,
                  dense: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskStatistics extends StatelessWidget {
  const _TaskStatistics({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Progress', style: theme.textTheme.titleSmall),
                ),
                Text(
                  '${(stats.completionRate * 100).round()}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CompletionBar(value: stats.completionRate, showCaption: false),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final status in TaskStatus.values)
                  TagChip(
                    label: '${status.label} ${stats.byStatus[status] ?? 0}',
                    color: status.color(theme),
                    dense: true,
                  ),
                if (stats.overdue > 0)
                  TagChip(
                    label: '${stats.overdue} overdue',
                    color: AppColors.error,
                    icon: Icons.error_outline_rounded,
                    dense: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 120, height: 16),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: double.infinity, height: 6),
            SizedBox(height: AppSpacing.lg),
            SkeletonBox(width: 200, height: 20),
          ],
        ),
      ),
    );
  }
}
