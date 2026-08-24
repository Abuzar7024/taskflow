import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/models/models.dart';
import 'package:taskflow/domain/entities/entities.dart';
import 'package:taskflow/domain/entities/enums.dart';

import '../support/harness.dart';

void main() {
  group('enum wire mapping', () {
    test('task status round-trips every value', () {
      for (final status in TaskStatus.values) {
        expect(TaskStatus.fromWire(status.wireValue), status);
      }
    });

    test('task priority round-trips every value', () {
      for (final priority in TaskPriority.values) {
        expect(TaskPriority.fromWire(priority.wireValue), priority);
      }
    });

    test('roles round-trip', () {
      expect(OrgRole.fromWire('org_admin'), OrgRole.orgAdmin);
      expect(OrgRole.fromWire('member'), OrgRole.member);
    });

    test('an unknown status fails loudly rather than defaulting', () {
      expect(
        () => TaskStatus.fromWire('nonsense'),
        throwsA(isA<FormatException>()),
      );
    });

    test('an unknown notification type degrades instead of throwing', () {
      expect(
        NotificationType.fromWire('something_new'),
        NotificationType.projectUpdated,
      );
    });

    test('priority weights order low to urgent', () {
      expect(TaskPriority.low.weight, lessThan(TaskPriority.medium.weight));
      expect(TaskPriority.medium.weight, lessThan(TaskPriority.high.weight));
      expect(TaskPriority.high.weight, lessThan(TaskPriority.urgent.weight));
    });
  });

  group('parsing the shipped asset', () {
    late Map<String, dynamic> json;

    setUpAll(() async {
      json = jsonDecode(await loadMockJson()) as Map<String, dynamic>;
    });

    test('every task parses, including null assignees', () {
      final tasks = (json['tasks'] as List)
          .cast<Map<String, dynamic>>()
          .map(TaskMapper.fromJson)
          .toList();

      expect(tasks.length, 15);
      expect(tasks.where((t) => t.assigneeId == null).length, 3);
      expect(tasks.every((t) => t.dueDate != null), isTrue);
    });

    test('every project parses', () {
      final projects = (json['projects'] as List)
          .cast<Map<String, dynamic>>()
          .map((p) => ProjectMapper.fromJson(p))
          .toList();

      expect(projects.length, 3);
      expect(projects.every((p) => p.status == ProjectStatus.active), isTrue);
    });

    test('every user, comment and notification parses', () {
      expect(
        (json['users'] as List)
            .cast<Map<String, dynamic>>()
            .map(UserMapper.fromJson)
            .length,
        5,
      );
      expect(
        (json['comments'] as List)
            .cast<Map<String, dynamic>>()
            .map(CommentMapper.fromJson)
            .length,
        4,
      );
      expect(
        (json['notifications'] as List)
            .cast<Map<String, dynamic>>()
            .map(NotificationMapper.fromJson)
            .length,
        3,
      );
    });

    test('credentials and login response parse', () {
      final auth = json['auth_mock'] as Map<String, dynamic>;
      final credentials = (auth['test_credentials'] as List)
          .cast<Map<String, dynamic>>()
          .map(MockCredential.fromJson)
          .toList();

      expect(credentials.length, 4);
      expect(credentials.where((c) => c.role.isAdmin).length, 2);

      final response = MockLoginResponse.fromJson(
        auth['mock_login_response'] as Map<String, dynamic>,
      );
      expect(response.accessTokenLifetimeSeconds, 900);
      expect(response.refreshTokenLifetimeSeconds, 604800);
    });

    test('task JSON survives a serialise/parse round trip', () {
      final original = TaskMapper.fromJson(
        (json['tasks'] as List).cast<Map<String, dynamic>>().first,
      );
      expect(TaskMapper.fromJson(original.toJson()), equals(original));
    });

    test('a task without a due date round-trips as null', () {
      final task = Task(
        id: 't',
        projectId: 'p',
        title: 'No due date',
        description: '',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(TaskMapper.fromJson(task.toJson()).dueDate, isNull);
    });
  });

  group('entity behaviour', () {
    final now = DateTime(2026, 2, 10);

    Task taskWith({
      TaskStatus status = TaskStatus.todo,
      DateTime? dueDate,
    }) {
      return Task(
        id: 't',
        projectId: 'p',
        title: 'Task',
        description: '',
        status: status,
        priority: TaskPriority.medium,
        dueDate: dueDate,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    test('an open task past its due date is overdue', () {
      expect(taskWith(dueDate: DateTime(2026, 2, 1)).isOverdue(now), isTrue);
    });

    test('a completed task is never overdue', () {
      expect(
        taskWith(status: TaskStatus.done, dueDate: DateTime(2026, 2, 1))
            .isOverdue(now),
        isFalse,
      );
    });

    test('a task due today is not overdue', () {
      expect(taskWith(dueDate: now).isOverdue(now), isFalse);
      expect(taskWith(dueDate: now).isDueToday(now), isTrue);
    });

    test('a task without a due date is never overdue', () {
      expect(taskWith().isOverdue(now), isFalse);
    });

    test('copyWith can clear the assignee explicitly', () {
      final assigned = taskWith().copyWith(assigneeId: 'user_1');
      expect(assigned.assigneeId, 'user_1');
      expect(assigned.copyWith(clearAssignee: true).assigneeId, isNull);
    });

    test('copyWith without arguments preserves every field', () {
      final task = taskWith(dueDate: now).copyWith(assigneeId: 'user_1');
      expect(task.copyWith(), equals(task));
    });

    test('initials handle one and two part names', () {
      expect(
        const User(id: 'u', name: 'Ava Thompson', email: 'a@b.test').initials,
        'AT',
      );
      expect(
        const User(id: 'u', name: 'Prince', email: 'a@b.test').initials,
        'P',
      );
      expect(
        const User(id: 'u', name: '  ', email: 'a@b.test').initials,
        '?',
      );
    });
  });
}
