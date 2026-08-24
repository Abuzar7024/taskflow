import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/entities/entities.dart';
import 'package:taskflow/domain/entities/enums.dart';
import 'package:taskflow/domain/entities/task_filter.dart';

Task task({
  required String id,
  String title = 'Task',
  String description = '',
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.medium,
  String? assigneeId,
  DateTime? dueDate,
  DateTime? createdAt,
}) {
  return Task(
    id: id,
    projectId: 'proj_1',
    title: title,
    description: description,
    status: status,
    priority: priority,
    assigneeId: assigneeId,
    dueDate: dueDate,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('TaskFilter.apply', () {
    final todo = task(id: 't1', status: TaskStatus.todo);
    final inProgress = task(id: 't2', status: TaskStatus.inProgress);
    final done = task(id: 't3', status: TaskStatus.done);
    final all = [todo, inProgress, done];

    test('no filter returns every task', () {
      expect(const TaskFilter().apply(all).length, 3);
    });

    test('filters by a single status', () {
      final result = const TaskFilter(
        statuses: {TaskStatus.todo},
      ).apply(all);
      expect(result.map((t) => t.id), ['t1']);
    });

    test('status filter is a union across selected values', () {
      final result = const TaskFilter(
        statuses: {TaskStatus.todo, TaskStatus.done},
      ).apply(all);
      expect(result.map((t) => t.id), containsAll(['t1', 't3']));
      expect(result.length, 2);
    });

    test('filters by priority', () {
      final tasks = [
        task(id: 'low', priority: TaskPriority.low),
        task(id: 'urgent', priority: TaskPriority.urgent),
      ];
      final result = const TaskFilter(
        priorities: {TaskPriority.urgent},
      ).apply(tasks);
      expect(result.map((t) => t.id), ['urgent']);
    });

    test('filters by assignee', () {
      final tasks = [
        task(id: 'mine', assigneeId: 'user_1'),
        task(id: 'theirs', assigneeId: 'user_2'),
        task(id: 'nobody'),
      ];
      final result = const TaskFilter(assigneeIds: {'user_1'}).apply(tasks);
      expect(result.map((t) => t.id), ['mine']);
    });

    test('the unassigned sentinel matches only tasks with no assignee', () {
      final tasks = [
        task(id: 'mine', assigneeId: 'user_1'),
        task(id: 'nobody'),
      ];
      final result = const TaskFilter(
        assigneeIds: {unassignedFilterId},
      ).apply(tasks);
      expect(result.map((t) => t.id), ['nobody']);
    });

    test('assignee filter combines real ids with the unassigned sentinel', () {
      final tasks = [
        task(id: 'mine', assigneeId: 'user_1'),
        task(id: 'theirs', assigneeId: 'user_2'),
        task(id: 'nobody'),
      ];
      final result = const TaskFilter(
        assigneeIds: {'user_1', unassignedFilterId},
      ).apply(tasks);
      expect(result.map((t) => t.id), containsAll(['mine', 'nobody']));
      expect(result.length, 2);
    });

    group('due-date range', () {
      final tasks = [
        task(id: 'early', dueDate: DateTime(2026, 1, 5)),
        task(id: 'mid', dueDate: DateTime(2026, 1, 15)),
        task(id: 'late', dueDate: DateTime(2026, 2, 1)),
        task(id: 'none'),
      ];

      test('includes both bounds', () {
        final result = TaskFilter(
          dueFrom: DateTime(2026, 1, 5),
          dueTo: DateTime(2026, 1, 15),
        ).apply(tasks);
        expect(result.map((t) => t.id), containsAll(['early', 'mid']));
        expect(result.length, 2);
      });

      test('an open-ended lower bound still filters', () {
        final result = TaskFilter(dueFrom: DateTime(2026, 1, 10)).apply(tasks);
        expect(result.map((t) => t.id), containsAll(['mid', 'late']));
      });

      test('an open-ended upper bound still filters', () {
        final result = TaskFilter(dueTo: DateTime(2026, 1, 10)).apply(tasks);
        expect(result.map((t) => t.id), ['early']);
      });

      test('tasks without a due date are excluded when a range is set', () {
        final result = TaskFilter(dueFrom: DateTime(2026, 1, 1)).apply(tasks);
        expect(result.map((t) => t.id), isNot(contains('none')));
      });

      test('bounds compare by day, ignoring any time component', () {
        final result = TaskFilter(
          dueFrom: DateTime(2026, 1, 15, 23, 59),
          dueTo: DateTime(2026, 1, 15, 0, 1),
        ).apply(tasks);
        expect(result.map((t) => t.id), ['mid']);
      });
    });

    group('search query', () {
      final tasks = [
        task(id: 'a', title: 'Fix broken contact form'),
        task(id: 'b', title: 'SEO audit', description: 'Technical review'),
      ];

      test('matches the title case-insensitively', () {
        expect(
          const TaskFilter(query: 'BROKEN').apply(tasks).map((t) => t.id),
          ['a'],
        );
      });

      test('matches the description', () {
        expect(
          const TaskFilter(query: 'technical').apply(tasks).map((t) => t.id),
          ['b'],
        );
      });

      test('a whitespace-only query is treated as no query', () {
        expect(const TaskFilter(query: '   ').apply(tasks).length, 2);
      });
    });

    test('dimensions combine as AND', () {
      final tasks = [
        task(
          id: 'match',
          status: TaskStatus.todo,
          priority: TaskPriority.urgent,
          assigneeId: 'user_1',
        ),
        task(
          id: 'wrongPriority',
          status: TaskStatus.todo,
          priority: TaskPriority.low,
          assigneeId: 'user_1',
        ),
        task(
          id: 'wrongAssignee',
          status: TaskStatus.todo,
          priority: TaskPriority.urgent,
          assigneeId: 'user_2',
        ),
      ];

      final result = const TaskFilter(
        statuses: {TaskStatus.todo},
        priorities: {TaskPriority.urgent},
        assigneeIds: {'user_1'},
      ).apply(tasks);

      expect(result.map((t) => t.id), ['match']);
    });

    test('does not mutate the input list', () {
      final input = [
        task(id: 'b', priority: TaskPriority.low),
        task(id: 'a', priority: TaskPriority.urgent),
      ];
      final before = List.of(input);
      const TaskFilter().apply(input);
      expect(input, equals(before));
    });
  });

  group('TaskFilter sorting', () {
    test('priority sort puts urgent first', () {
      final tasks = [
        task(id: 'low', priority: TaskPriority.low),
        task(id: 'urgent', priority: TaskPriority.urgent),
        task(id: 'medium', priority: TaskPriority.medium),
      ];
      final result = const TaskFilter().apply(tasks);
      expect(result.first.id, 'urgent');
      expect(result.last.id, 'low');
    });

    test('due-date sort is ascending with nulls last', () {
      final tasks = [
        task(id: 'none'),
        task(id: 'late', dueDate: DateTime(2026, 3, 1)),
        task(id: 'soon', dueDate: DateTime(2026, 1, 2)),
      ];
      final result = const TaskFilter(sort: TaskSort.dueDateAsc).apply(tasks);
      expect(result.map((t) => t.id), ['soon', 'late', 'none']);
    });

    test('title sort is case-insensitive', () {
      final tasks = [
        task(id: 'b', title: 'beta'),
        task(id: 'a', title: 'Alpha'),
      ];
      final result = const TaskFilter(sort: TaskSort.titleAsc).apply(tasks);
      expect(result.map((t) => t.id), ['a', 'b']);
    });

    test('newest sort uses createdAt descending', () {
      final tasks = [
        task(id: 'old', createdAt: DateTime(2025, 1, 1)),
        task(id: 'new', createdAt: DateTime(2026, 6, 1)),
      ];
      final result = const TaskFilter(sort: TaskSort.createdDesc).apply(tasks);
      expect(result.map((t) => t.id), ['new', 'old']);
    });
  });

  group('active state', () {
    test('a default filter is inactive', () {
      expect(const TaskFilter().isActive, isFalse);
      expect(const TaskFilter().activeCount, 0);
    });

    test('counts each populated dimension once', () {
      final filter = TaskFilter(
        statuses: const {TaskStatus.todo, TaskStatus.done},
        priorities: const {TaskPriority.high},
        query: 'seo',
        dueFrom: DateTime(2026, 1, 1),
      );
      expect(filter.activeCount, 4);
      expect(filter.isActive, isTrue);
    });

    test('cleared() drops filters but keeps the sort', () {
      const filter = TaskFilter(
        statuses: {TaskStatus.done},
        sort: TaskSort.titleAsc,
      );
      final cleared = filter.cleared();
      expect(cleared.isActive, isFalse);
      expect(cleared.sort, TaskSort.titleAsc);
    });
  });
}
