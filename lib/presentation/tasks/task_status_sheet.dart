import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../widgets/common.dart';
import 'task_controller.dart';

/// Quick status picker, reachable from any task card.
Future<void> showTaskStatusSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final selected = await showModalBottomSheet<TaskStatus>(
    context: context,
    builder: (context) => _OptionSheet<TaskStatus>(
      title: 'Move task to',
      options: TaskStatus.values,
      current: task.status,
      labelOf: (s) => s.label,
      colorOf: (s) => s.color,
      iconOf: (s) => s.icon,
    ),
  );

  if (selected == null || selected == task.status || !context.mounted) return;

  final result = await ref
      .read(taskControllerProvider.notifier)
      .setStatus(task, selected);
  if (!context.mounted) return;

  showAppSnackBar(
    context,
    result.isSuccess
        ? 'Moved to ${selected.label}.'
        : result.errorOrNull!,
    isError: !result.isSuccess,
  );
}

/// Quick priority picker.
Future<void> showTaskPrioritySheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final selected = await showModalBottomSheet<TaskPriority>(
    context: context,
    builder: (context) => _OptionSheet<TaskPriority>(
      title: 'Set priority',
      options: TaskPriority.values.reversed.toList(),
      current: task.priority,
      labelOf: (p) => p.label,
      colorOf: (p) => p.color,
      iconOf: (p) => p.icon,
    ),
  );

  if (selected == null || selected == task.priority || !context.mounted) return;

  final result = await ref
      .read(taskControllerProvider.notifier)
      .setPriority(task, selected);
  if (!context.mounted) return;

  showAppSnackBar(
    context,
    result.isSuccess
        ? 'Priority set to ${selected.label}.'
        : result.errorOrNull!,
    isError: !result.isSuccess,
  );
}

/// Shared single-select sheet for the enum pickers above.
class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.labelOf,
    required this.colorOf,
    required this.iconOf,
  });

  final String title;
  final List<T> options;
  final T current;
  final String Function(T) labelOf;
  final Color Function(T) colorOf;
  final IconData Function(T) iconOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          for (final option in options)
            ListTile(
              leading: Icon(iconOf(option), color: colorOf(option)),
              title: Text(labelOf(option)),
              trailing: option == current
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(option),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
