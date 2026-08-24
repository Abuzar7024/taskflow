import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/task_filter.dart';
import '../projects/project_providers.dart';
import '../widgets/offline_banner.dart';
import '../widgets/state_views.dart';
import 'task_card.dart';
import 'task_filter_sheet.dart';
import 'task_providers.dart';
import 'task_status_sheet.dart';

/// All tasks across the organization, with the full filter set.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const scope = FilterScopes.allTasks;
    final tasks = ref.watch(tasksProvider);
    final filter = ref.watch(taskFilterProvider(scope));
    final projects = ref.watch(projectsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          FilterButton(
            activeCount: filter.activeCount,
            onPressed: () => showTaskFilterSheet(context, ref, scope: scope),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: projects.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newTask()),
              icon: const Icon(Icons.add),
              label: const Text('New task'),
            ),
      body: Column(
        children: [
          OfflineBanner(cachedAt: ref.watch(tasksCachedAtProvider)),
          if (filter.isActive)
            ActiveFilterBar(
              filter: filter,
              onClear: () =>
                  ref.read(taskFilterProvider(scope).notifier).state =
                      filter.cleared(),
            ),
          Expanded(
            child: tasks.when(
              loading: () => const SkeletonList(),
              error: (error, _) => ErrorStateView(
                message: messageFor(error),
                onRetry: () => ref.invalidate(tasksProvider),
              ),
              data: (items) => _TaskListBody(
                all: items,
                filter: filter,
                scope: scope,
                projectNames: {for (final p in projects) p.id: p.name},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskListBody extends ConsumerWidget {
  const _TaskListBody({
    required this.all,
    required this.filter,
    required this.scope,
    required this.projectNames,
  });

  final List<Task> all;
  final TaskFilter filter;
  final String scope;
  final Map<String, String> projectNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.checklist,
        title: 'No tasks yet',
        message: 'Tasks you create will show up here.',
        actionLabel: projectNames.isEmpty ? null : 'Create a task',
        onAction: projectNames.isEmpty
            ? null
            : () => context.push(Routes.newTask()),
      );
    }

    final visible = filter.apply(all);

    if (visible.isEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'No tasks found',
        message: 'No tasks match your filters. Try widening or clearing them.',
        actionLabel: 'Clear filters',
        onAction: () =>
            ref.read(taskFilterProvider(scope).notifier).state =
                filter.cleared(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tasksProvider);
        await ref.read(tasksProvider.future);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl * 2.5,
        ),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final task = visible[index];
          return TaskCard(
            task: task,
            showProject: projectNames[task.projectId],
            onTap: () => context.push(Routes.task(task.id)),
            onStatusTap: () => showTaskStatusSheet(context, ref, task),
          );
        },
      ),
    );
  }
}

/// Filter icon with a count badge.
class FilterButton extends StatelessWidget {
  const FilterButton({
    required this.activeCount,
    required this.onPressed,
    super.key,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Filter tasks',
      icon: Badge(
        isLabelVisible: activeCount > 0,
        label: Text('$activeCount'),
        child: const Icon(Icons.tune),
      ),
    );
  }
}

/// Strip summarising the active filters, with a clear-all action.
class ActiveFilterBar extends StatelessWidget {
  const ActiveFilterBar({
    required this.filter,
    required this.onClear,
    super.key,
  });

  final TaskFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.filter_alt, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${filter.activeCount} filter${filter.activeCount == 1 ? '' : 's'} active',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Clear all')),
          ],
        ),
      ),
    );
  }
}
