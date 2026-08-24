import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
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

class ProjectCard extends StatelessWidget {
  const ProjectCard({required this.project, super.key});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  TagChip(
                    label: Plurals.countLabel(project.taskCount),
                    icon: Icons.checklist_rtl,
                    dense: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TagChip(
                    label: project.status.label,
                    icon: Icons.circle,
                    dense: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
