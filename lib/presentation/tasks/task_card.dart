import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../domain/entities/entities.dart';
import '../providers.dart';
import '../widgets/common.dart';
import 'task_providers.dart';

/// Task row used on the dashboard, the task list and project detail.
///
/// Shows title, status, priority, assignee and due date, and exposes a
/// one-tap status change so the common action does not require opening the
/// task.
class TaskCard extends ConsumerWidget {
  const TaskCard({
    required this.task,
    required this.onTap,
    this.onStatusTap,
    this.showProject,
    super.key,
  });

  final Task task;
  final VoidCallback onTap;

  /// When provided, the leading status icon becomes a button.
  final VoidCallback? onStatusTap;

  /// Project name, shown when the list spans multiple projects.
  final String? showProject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();
    final overdue = task.isOverdue(now);
    final assignee = ref
        .watch(userDirectoryProvider)
        .maybeWhen(
          data: (users) => task.assigneeId == null
              ? null
              : users[task.assigneeId],
          orElse: () => null,
        );

    return Card(
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusButton(task: task, onTap: onStatusTap),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            decoration: task.status.isComplete
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.status.isComplete
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                        if (showProject != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            showProject!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Wrap keeps the metadata row from overflowing when the
              // assignee name or due-date label is long.
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip(status: task.status, dense: true),
                  PriorityChip(priority: task.priority, dense: true),
                  if (task.dueDate != null)
                    DueDateChip(
                      dueDate: task.dueDate!,
                      now: now,
                      isOverdue: overdue,
                      dense: true,
                    ),
                  AssigneeLabel(user: assignee),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular status indicator. Tappable when [onTap] is supplied.
class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.task, this.onTap});

  final Task task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(task.status.icon, size: 20, color: task.status.color);

    if (onTap == null) return Padding(padding: const EdgeInsets.all(2), child: icon);

    return Tooltip(
      message: 'Change status',
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(padding: const EdgeInsets.all(2), child: icon),
      ),
    );
  }
}
