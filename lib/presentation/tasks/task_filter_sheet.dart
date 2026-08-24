import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/task_filter.dart';
import '../widgets/common.dart';
import 'task_providers.dart';

/// Full filter editor. Edits a local copy and only commits on "Apply", so
/// backing out of the sheet leaves the list untouched.
Future<void> showTaskFilterSheet(
  BuildContext context,
  WidgetRef ref, {
  required String scope,
}) async {
  final current = ref.read(taskFilterProvider(scope));
  final members = ref.read(orgMembersProvider).valueOrNull ?? const [];

  final result = await showModalBottomSheet<TaskFilter>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TaskFilterSheet(initial: current, members: members),
  );

  if (result != null) {
    ref.read(taskFilterProvider(scope).notifier).state = result;
  }
}

class _TaskFilterSheet extends StatefulWidget {
  const _TaskFilterSheet({required this.initial, required this.members});

  final TaskFilter initial;
  final List<OrgMember> members;

  @override
  State<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<_TaskFilterSheet> {
  late TaskFilter _draft = widget.initial;
  late final TextEditingController _queryController = TextEditingController(
    text: widget.initial.query,
  );

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _toggleStatus(TaskStatus status) {
    setState(() {
      final next = Set<TaskStatus>.from(_draft.statuses);
      next.contains(status) ? next.remove(status) : next.add(status);
      _draft = _draft.copyWith(statuses: next);
    });
  }

  void _togglePriority(TaskPriority priority) {
    setState(() {
      final next = Set<TaskPriority>.from(_draft.priorities);
      next.contains(priority) ? next.remove(priority) : next.add(priority);
      _draft = _draft.copyWith(priorities: next);
    });
  }

  void _toggleAssignee(String id) {
    setState(() {
      final next = Set<String>.from(_draft.assigneeIds);
      next.contains(id) ? next.remove(id) : next.add(id);
      _draft = _draft.copyWith(assigneeIds: next);
    });
  }

  Future<void> _pickDueRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _draft.dueFrom != null && _draft.dueTo != null
          ? DateTimeRange(start: _draft.dueFrom!, end: _draft.dueTo!)
          : null,
    );
    if (range == null) return;
    setState(() {
      _draft = _draft.copyWith(dueFrom: range.start, dueTo: range.end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter tasks',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _queryController.clear();
                        setState(() => _draft = _draft.cleared());
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const Divider(height: AppSpacing.lg),

              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  shrinkWrap: true,
                  children: [
                    TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        hintText: 'Title or description',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _draft.query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _queryController.clear();
                                  setState(
                                    () => _draft = _draft.copyWith(query: ''),
                                  );
                                },
                              ),
                      ),
                      onChanged: (value) =>
                          setState(() => _draft = _draft.copyWith(query: value)),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const SectionHeader(title: 'Status'),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final status in TaskStatus.values)
                          FilterChip(
                            label: Text(status.label),
                            avatar: Icon(
                              status.icon,
                              size: 16,
                              color: status.color,
                            ),
                            selected: _draft.statuses.contains(status),
                            onSelected: (_) => _toggleStatus(status),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const SectionHeader(title: 'Priority'),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final priority in TaskPriority.values.reversed)
                          FilterChip(
                            label: Text(priority.label),
                            avatar: Icon(
                              priority.icon,
                              size: 16,
                              color: priority.color,
                            ),
                            selected: _draft.priorities.contains(priority),
                            onSelected: (_) => _togglePriority(priority),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const SectionHeader(title: 'Assignee'),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilterChip(
                          label: const Text('Unassigned'),
                          selected: _draft.assigneeIds.contains(
                            unassignedFilterId,
                          ),
                          onSelected: (_) =>
                              _toggleAssignee(unassignedFilterId),
                        ),
                        for (final member in widget.members)
                          FilterChip(
                            label: Text(member.user.name),
                            avatar: UserAvatar(user: member.user, radius: 10),
                            selected: _draft.assigneeIds.contains(
                              member.user.id,
                            ),
                            onSelected: (_) => _toggleAssignee(member.user.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const SectionHeader(title: 'Due date'),
                    const SizedBox(height: AppSpacing.sm),
                    _DueRangeField(
                      from: _draft.dueFrom,
                      to: _draft.dueTo,
                      onPick: _pickDueRange,
                      onClear: () => setState(
                        () => _draft = _draft.copyWith(
                          clearDueFrom: true,
                          clearDueTo: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const SectionHeader(title: 'Sort by'),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final sort in TaskSort.values)
                          ChoiceChip(
                            label: Text(sort.label),
                            selected: _draft.sort == sort,
                            onSelected: (_) => setState(
                              () => _draft = _draft.copyWith(sort: sort),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_draft),
                    child: const Text('Apply filters'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueRangeField extends StatelessWidget {
  const _DueRangeField({
    required this.from,
    required this.to,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRange = from != null || to != null;

    return InkWell(
      onTap: onPick,
      borderRadius: AppRadius.field,
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.date_range_outlined),
          suffixIcon: hasRange
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : null,
        ),
        child: Text(
          hasRange
              ? '${from == null ? 'Any' : Dates.full(from!)} → '
                    '${to == null ? 'Any' : Dates.full(to!)}'
              : 'Any due date',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: hasRange ? null : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
