import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../domain/entities/entities.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import 'task_controller.dart';
import 'task_providers.dart';

/// Assignee picker limited to members of the current organization.
///
/// The repository re-validates the choice, so this list is a convenience
/// rather than the security boundary.
Future<void> showAssigneeSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final selection = await showModalBottomSheet<_AssigneeSelection>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AssigneeSheet(currentAssigneeId: task.assigneeId),
  );

  if (selection == null || !context.mounted) return;
  if (selection.userId == task.assigneeId) return;

  final result = await ref
      .read(taskControllerProvider.notifier)
      .assign(task, selection.userId);
  if (!context.mounted) return;

  showAppSnackBar(
    context,
    result.isSuccess
        ? (selection.userId == null
              ? 'Task unassigned.'
              : 'Assigned to ${selection.name}.')
        : result.errorOrNull!,
    isError: !result.isSuccess,
  );
}

/// Wraps the chosen id so "unassign" (null) is distinguishable from a
/// dismissed sheet (also null, but as the sheet result).
class _AssigneeSelection {
  const _AssigneeSelection(this.userId, this.name);

  final String? userId;
  final String? name;
}

class _AssigneeSheet extends ConsumerWidget {
  const _AssigneeSheet({required this.currentAssigneeId});

  final String? currentAssigneeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members = ref.watch(orgMembersProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
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
              child: Text('Assign task', style: theme.textTheme.titleMedium),
            ),
            Flexible(
              child: members.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: LoadingView(),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'We could not load your teammates. Close and try again.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                data: (items) => ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const UserAvatar(user: null, radius: 18),
                      title: const Text('Unassigned'),
                      trailing: currentAssigneeId == null
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(
                        context,
                      ).pop(const _AssigneeSelection(null, null)),
                    ),
                    const Divider(height: 1),
                    for (final member in items)
                      ListTile(
                        leading: UserAvatar(user: member.user),
                        title: Text(member.user.name),
                        subtitle: Text(member.role.label),
                        trailing: member.user.id == currentAssigneeId
                            ? Icon(
                                Icons.check,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(
                          _AssigneeSelection(member.user.id, member.user.name),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
