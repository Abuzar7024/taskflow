import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import 'app_components.dart';

// The shared primitives live in app_components.dart; re-exported so screens
// need a single import.
export 'app_components.dart';

/// Status label for a task.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.dense = false});

  final TaskStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: status.label,
      tone: status.color,
      icon: status.icon,
      dense: dense,
    );
  }
}

/// Priority label for a task.
class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority, this.dense = false});

  final TaskPriority priority;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: priority.label,
      tone: priority.color,
      icon: priority.icon,
      dense: dense,
    );
  }
}

/// Due date shown relative to today, tinted red once overdue.
class DueDateChip extends StatelessWidget {
  const DueDateChip({
    super.key,
    this.task,
    this.dueDate,
    this.isOverdue,
    required this.now,
    this.dense = false,
  }) : assert(task != null || dueDate != null, 'provide a task or a dueDate');

  final Task? task;

  /// Supplied instead of [task] when only the date is known.
  final DateTime? dueDate;
  final bool? isOverdue;
  final DateTime now;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final due = task?.dueDate ?? dueDate;
    if (due == null) return const SizedBox.shrink();

    final overdue = isOverdue ?? task?.isOverdue(now) ?? false;
    final dueToday = task?.isDueToday(now) ?? false;
    final tone = overdue
        ? AppPalette.coral
        : dueToday
        ? AppPalette.amber
        : Theme.of(context).surfaces.textMuted;

    return AppChip(
      label: Dates.relativeDay(due, now),
      tone: tone,
      icon: overdue
          ? Icons.error_outline_rounded
          : Icons.calendar_today_rounded,
      dense: dense,
    );
  }
}

/// Avatar for a user, falling back to initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    double? size,
    double? radius,
  }) : size = size ?? (radius != null ? radius * 2 : 40);

  final User? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = user;
    if (resolved == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).surfaces.cardElevated,
          border: Border.all(color: Theme.of(context).surfaces.border),
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: size * 0.5,
          color: Theme.of(context).surfaces.textMuted,
        ),
      );
    }

    return AppAvatar(
      initials: resolved.initials,
      imageUrl: resolved.avatarUrl,
      size: size,
      tone: _toneFor(resolved.id),
    );
  }

  /// Stable per-user accent so the same person keeps the same colour.
  static Color _toneFor(String id) {
    const palette = [
      AppPalette.indigo,
      AppPalette.cyan,
      AppPalette.violet,
      AppPalette.emerald,
      AppPalette.amber,
    ];
    return palette[id.hashCode.abs() % palette.length];
  }
}

/// Avatar plus name, or a muted "Unassigned" when there is no assignee.
class AssigneeLabel extends StatelessWidget {
  const AssigneeLabel({
    super.key,
    required this.user,
    this.size = 24,
    this.showName = true,
  });

  final User? user;
  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(user: user, size: size),
        if (showName) ...[
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              user?.name ?? 'Unassigned',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: user == null
                    ? theme.surfaces.textMuted
                    : theme.surfaces.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Progress bar with a caption showing completed vs total.
class CompletionBar extends StatelessWidget {
  const CompletionBar({
    super.key,
    this.stats,
    this.value,
    this.showCaption = true,
  }) : assert(stats != null || value != null, 'provide stats or a value');

  final TaskStats? stats;

  /// Completion ratio supplied directly when no [TaskStats] is at hand.
  final double? value;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = stats?.completionRate ?? value ?? 0;
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCaption) ...[
          Row(
            children: [
              Text('Progress', style: theme.textTheme.labelMedium),
              const Spacer(),
              Text(
                '$percent%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppProgressBar(
          value: ratio,
          gradient: theme.surfaces.brandGradient,
        ),
        if (showCaption && stats != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${stats!.completed} of '
            '${Plurals.count(stats!.total, 'task')} complete',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Inline error strip shown above a form after a failed submission.
class InlineErrorBanner extends StatelessWidget {
  const InlineErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppFadeIn(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.surfaces.tint(theme.colorScheme.error),
          borderRadius: AppRadius.field,
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legacy aliases kept so existing screens compile unchanged.
typedef TagChip = AppChip;
typedef SectionHeader = AppSectionHeader;
typedef ButtonSpinner = AppButtonSpinner;
