import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';

/// Small pill used for status, priority and metadata throughout the app.
class TagChip extends StatelessWidget {
  const TagChip({
    required this.label,
    this.color,
    this.icon,
    this.dense = false,
    super.key,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tintFor(accent, theme.brightness),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: accent),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
                ?.copyWith(color: accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {this.dense = false, super.key});

  final TaskStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TagChip(
      label: status.label,
      color: status.color,
      icon: status.icon,
      dense: dense,
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip(this.priority, {this.dense = false, super.key});

  final TaskPriority priority;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TagChip(
      label: priority.label,
      color: priority.color,
      icon: priority.icon,
      dense: dense,
    );
  }
}

/// Due-date chip that turns red once the task is overdue.
class DueDateChip extends StatelessWidget {
  const DueDateChip({
    required this.dueDate,
    required this.now,
    required this.isOverdue,
    this.dense = false,
    super.key,
  });

  final DateTime dueDate;
  final DateTime now;
  final bool isOverdue;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TagChip(
      label: Dates.relativeDay(dueDate, now),
      color: isOverdue ? AppColors.overdue : null,
      icon: isOverdue ? Icons.event_busy : Icons.event_outlined,
      dense: dense,
    );
  }
}

/// Circular avatar falling back to initials.
///
/// The mock avatars are remote URLs, so the initials also cover the offline
/// case where the image cannot load.
class UserAvatar extends StatelessWidget {
  const UserAvatar({required this.user, this.radius = 18, super.key});

  final User? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final person = user;

    if (person == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person_outline,
          size: radius,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final initials = Text(
      person.initials,
      style: TextStyle(
        fontSize: radius * 0.72,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );

    final avatarUrl = person.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
      onForegroundImageError: avatarUrl == null ? null : (_, _) {},
      child: initials,
    );
  }
}

/// Assignee row: avatar plus name, or a muted "Unassigned".
class AssigneeLabel extends StatelessWidget {
  const AssigneeLabel({required this.user, this.radius = 11, super.key});

  final User? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(user: user, radius: radius),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            user?.name ?? 'Unassigned',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: user == null ? FontStyle.italic : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Section header with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (action != null) action!,
      ],
    );
  }
}

/// Thin progress bar used for completion rates.
class CompletionBar extends StatelessWidget {
  const CompletionBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 6,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.08),
      ),
    );
  }
}

/// Confirmation dialog for destructive actions. Resolves to true on confirm.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Consistent feedback for completed and failed actions.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.errorContainer : null,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
}

/// Spinner sized to sit inside a filled button while a request runs.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

/// Inline error banner used by forms and auth screens.
class InlineErrorBanner extends StatelessWidget {
  const InlineErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: AppRadius.field,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
