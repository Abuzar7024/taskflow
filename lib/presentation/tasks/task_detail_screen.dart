import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../projects/project_providers.dart';
import '../providers.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import 'assignee_sheet.dart';
import 'task_controller.dart';
import 'task_providers.dart';
import 'task_status_sheet.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskByIdProvider(taskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          if (task.hasValue) ...[
            IconButton(
              onPressed: () => context.push(Routes.editTask(taskId)),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit task',
            ),
            IconButton(
              onPressed: () => _confirmDelete(context, ref, task.requireValue),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete task',
            ),
          ],
        ],
      ),
      body: task.when(
        loading: () => const LoadingView(message: 'Loading task…'),
        error: (error, _) => ErrorStateView(
          message: messageFor(error),
          onRetry: () => ref.invalidate(taskByIdProvider(taskId)),
        ),
        data: (data) => _TaskBody(task: data),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete task?',
      message: '"${task.title}" will be permanently removed.',
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(taskControllerProvider.notifier)
        .delete(task);
    if (!context.mounted) return;

    if (result.isSuccess) {
      showAppSnackBar(context, 'Task deleted.');
      context.pop();
    } else {
      showAppSnackBar(context, result.errorOrNull!, isError: true);
    }
  }
}

class _TaskBody extends ConsumerWidget {
  const _TaskBody({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();
    final isBusy = ref.watch(taskControllerProvider);
    final projectName = ref
        .watch(projectByIdProvider(task.projectId))
        .valueOrNull
        ?.name;
    final assignee = ref
        .watch(userDirectoryProvider)
        .valueOrNull?[task.assigneeId];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(taskByIdProvider(task.id));
        ref.invalidate(taskCommentsProvider(task.id));
        await ref.read(taskByIdProvider(task.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(task.title, style: theme.textTheme.titleLarge),
          if (projectName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () => context.push(Routes.project(task.projectId)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      projectName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          if (task.description.isNotEmpty) ...[
            Text(task.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
          ],

          Card(
            child: Column(
              children: [
                _DetailRow(
                  icon: task.status.icon,
                  iconColor: task.status.color(theme),
                  label: 'Status',
                  value: task.status.label,
                  onTap: isBusy
                      ? null
                      : () => showTaskStatusSheet(context, ref, task),
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: task.priority.icon,
                  iconColor: task.priority.color(theme),
                  label: 'Priority',
                  value: task.priority.label,
                  onTap: isBusy
                      ? null
                      : () => showTaskPrioritySheet(context, ref, task),
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Assignee',
                  value: assignee?.name ?? 'Unassigned',
                  isMuted: assignee == null,
                  onTap: isBusy
                      ? null
                      : () => showAssigneeSheet(context, ref, task),
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: task.isOverdue(now)
                      ? Icons.event_busy
                      : Icons.event_outlined,
                  iconColor: task.isOverdue(now) ? AppColors.error : null,
                  label: 'Due date',
                  value: task.dueDate == null
                      ? 'No due date'
                      : '${Dates.full(task.dueDate!)} · '
                            '${Dates.relativeDay(task.dueDate!, now)}',
                  isMuted: task.dueDate == null,
                  onTap: () => context.push(Routes.editTask(task.id)),
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.schedule,
                  label: 'Created',
                  value: Dates.dateTime(task.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Comments'),
          const SizedBox(height: AppSpacing.sm),
          _CommentsSection(task: task),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.onTap,
    this.isMuted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontStyle: isMuted ? FontStyle.italic : null,
                  color: isMuted ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  const _CommentsSection({required this.task});

  final Task task;

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;

    final result = await ref
        .read(taskControllerProvider.notifier)
        .addComment(widget.task, body);
    if (!mounted) return;

    if (result.isSuccess) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    } else {
      showAppSnackBar(context, result.errorOrNull!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(taskCommentsProvider(widget.task.id));
    final users = ref.watch(userDirectoryProvider).valueOrNull ?? const {};
    final now = ref.watch(clockProvider)();
    final isBusy = ref.watch(taskControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        comments.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: SkeletonBox(width: double.infinity, height: 56),
          ),
          error: (error, _) => Text(
            messageFor(error),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'No comments yet. Start the conversation.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final comment in items)
                      _CommentTile(
                        comment: comment,
                        author: users[comment.authorId],
                        now: now,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Add a comment',
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                enabled: !isBusy,
                onSubmitted: (_) => _post(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: isBusy ? null : _post,
              icon: const Icon(Icons.send, size: 18),
              tooltip: 'Post comment',
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.author,
    required this.now,
  });

  final Comment comment;
  final User? author;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(user: author, radius: 14),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        author?.name ?? 'Unknown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      Dates.timeAgo(comment.createdAt, now),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
