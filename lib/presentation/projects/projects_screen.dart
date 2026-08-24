import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../core/theme/status_colors.dart';
import '../providers.dart';
import '../tasks/task_providers.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/offline_banner.dart';
import '../widgets/state_views.dart';
import 'project_providers.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.newProject()),
        icon: const Icon(Icons.add),
        label: const Text('New project'),
      ),
      body: Column(
        children: [
          OfflineBanner(cachedAt: ref.watch(projectsCachedAtProvider)),
          Expanded(
            child: projects.when(
              loading: () => const SkeletonList(itemHeight: 116),
              error: (error, _) => ErrorStateView(
                message: messageFor(error),
                onRetry: () => ref.invalidate(projectsProvider),
              ),
              data: (items) => items.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_outlined,
                      title: 'No projects yet',
                      message:
                          'Create your first project to start organising work.',
                      actionLabel: 'Create a project',
                      onAction: () => context.push(Routes.newProject()),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(projectsProvider);
                        await ref.read(projectsProvider.future);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          // Room for the FAB.
                          AppSpacing.xxl * 2.5,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) =>
                            ProjectCard(project: items[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectCard extends ConsumerWidget {
  const ProjectCard({required this.project, super.key});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();

    // Stats come from the project's own tasks so the card reflects live data
    // rather than the seed file's stored counter.
    final tasks = ref.watch(projectTasksProvider(project.id));
    final stats = tasks.maybeWhen(
      data: (items) => TaskStats.from(items, now),
      orElse: () => null,
    );
    final assignees = tasks.maybeWhen(
      data: (items) => items
          .map((t) => t.assigneeId)
          .whereType<String>()
          .toSet()
          .toList(),
      orElse: () => const <String>[],
    );
    final directory = ref
        .watch(userDirectoryProvider)
        .maybeWhen(data: (d) => d, orElse: () => const <String, User>{});

    return AppCard(
      onTap: () => context.push(Routes.project(project.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconTile(
                icon: Icons.folder_rounded,
                tone: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Updated ${Dates.timeAgo(project.createdAt, now)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              if (stats != null)
                ProgressRing(value: stats.completionRate, size: 48, strokeWidth: 5),
            ],
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppProgressBar(
            value: stats?.completionRate ?? 0,
            
            height: 6,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppChip(
                      label: Plurals.countLabel(project.taskCount),
                      icon: Icons.checklist_rtl_rounded,
                      tone: theme.c.textMuted,
                      dense: true,
                    ),
                    AppChip(
                      label: project.status.label,
                      icon: Icons.circle,
                      tone: project.status.color(theme),
                      dense: true,
                    ),
                    if (stats != null && stats.overdue > 0)
                      AppChip(
                        label: '${stats.overdue} overdue',
                        icon: Icons.error_outline_rounded,
                        tone: AppColors.error,
                        dense: true,
                      ),
                  ],
                ),
              ),
              if (assignees.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                AppAvatarStack(
                  initials: [
                    for (final id in assignees)
                      directory[id]?.initials ?? '?',
                  ],
                  size: 26,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
