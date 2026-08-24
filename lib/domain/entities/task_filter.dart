import 'package:equatable/equatable.dart';

import 'entities.dart';
import 'enums.dart';

/// Sentinel for the "Unassigned" choice in the assignee filter, which cannot
/// be expressed as a user id.
const String unassignedFilterId = '__unassigned__';

enum TaskSort {
  priorityDesc('Priority'),
  dueDateAsc('Due date'),
  createdDesc('Newest'),
  titleAsc('Title');

  const TaskSort(this.label);

  final String label;
}

/// Declarative description of the active task filters.
///
/// [apply] is a pure function so the whole filtering surface can be unit
/// tested without building a widget.
class TaskFilter extends Equatable {
  const TaskFilter({
    this.statuses = const {},
    this.priorities = const {},
    this.assigneeIds = const {},
    this.dueFrom,
    this.dueTo,
    this.query = '',
    this.sort = TaskSort.priorityDesc,
  });

  /// Empty set means "no constraint on this dimension".
  final Set<TaskStatus> statuses;
  final Set<TaskPriority> priorities;

  /// May contain [unassignedFilterId] alongside real user ids.
  final Set<String> assigneeIds;

  final DateTime? dueFrom;
  final DateTime? dueTo;
  final String query;
  final TaskSort sort;

  bool get isActive =>
      statuses.isNotEmpty ||
      priorities.isNotEmpty ||
      assigneeIds.isNotEmpty ||
      dueFrom != null ||
      dueTo != null ||
      query.trim().isNotEmpty;

  /// Number of active filter dimensions, shown as a badge on the filter button.
  int get activeCount {
    var count = 0;
    if (statuses.isNotEmpty) count++;
    if (priorities.isNotEmpty) count++;
    if (assigneeIds.isNotEmpty) count++;
    if (dueFrom != null || dueTo != null) count++;
    if (query.trim().isNotEmpty) count++;
    return count;
  }

  List<Task> apply(List<Task> tasks) {
    final normalizedQuery = query.trim().toLowerCase();

    final filtered = tasks.where((task) {
      if (statuses.isNotEmpty && !statuses.contains(task.status)) return false;
      if (priorities.isNotEmpty && !priorities.contains(task.priority)) {
        return false;
      }
      if (assigneeIds.isNotEmpty && !_matchesAssignee(task)) return false;
      if (!_matchesDueRange(task)) return false;
      if (normalizedQuery.isNotEmpty && !_matchesQuery(task, normalizedQuery)) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort(_comparator);
    return filtered;
  }

  bool _matchesAssignee(Task task) {
    final assignee = task.assigneeId;
    if (assignee == null) return assigneeIds.contains(unassignedFilterId);
    return assigneeIds.contains(assignee);
  }

  /// Range bounds are inclusive and compared by calendar day. A task with no
  /// due date is excluded whenever a range is set.
  bool _matchesDueRange(Task task) {
    if (dueFrom == null && dueTo == null) return true;
    final due = task.dueDate;
    if (due == null) return false;

    final day = DateTime(due.year, due.month, due.day);
    final from = dueFrom;
    final to = dueTo;

    if (from != null &&
        day.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (to != null && day.isAfter(DateTime(to.year, to.month, to.day))) {
      return false;
    }
    return true;
  }

  bool _matchesQuery(Task task, String normalizedQuery) {
    return task.title.toLowerCase().contains(normalizedQuery) ||
        task.description.toLowerCase().contains(normalizedQuery);
  }

  int _comparator(Task a, Task b) {
    return switch (sort) {
      TaskSort.priorityDesc =>
        b.priority.weight.compareTo(a.priority.weight) != 0
            ? b.priority.weight.compareTo(a.priority.weight)
            : _byDueDate(a, b),
      TaskSort.dueDateAsc => _byDueDate(a, b),
      TaskSort.createdDesc => b.createdAt.compareTo(a.createdAt),
      TaskSort.titleAsc =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    };
  }

  /// Tasks without a due date sort last regardless of direction.
  static int _byDueDate(Task a, Task b) {
    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue == null && bDue == null) return a.createdAt.compareTo(b.createdAt);
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    final byDue = aDue.compareTo(bDue);
    return byDue != 0 ? byDue : a.createdAt.compareTo(b.createdAt);
  }

  TaskFilter copyWith({
    Set<TaskStatus>? statuses,
    Set<TaskPriority>? priorities,
    Set<String>? assigneeIds,
    DateTime? dueFrom,
    bool clearDueFrom = false,
    DateTime? dueTo,
    bool clearDueTo = false,
    String? query,
    TaskSort? sort,
  }) {
    return TaskFilter(
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      dueFrom: clearDueFrom ? null : (dueFrom ?? this.dueFrom),
      dueTo: clearDueTo ? null : (dueTo ?? this.dueTo),
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }

  /// Clears every dimension but keeps the chosen sort order.
  TaskFilter cleared() => TaskFilter(sort: sort);

  @override
  List<Object?> get props => [
    statuses,
    priorities,
    assigneeIds,
    dueFrom,
    dueTo,
    query,
    sort,
  ];
}
