import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/constants/dev_settings.dart';
import 'package:taskflow/core/errors/app_exception.dart';
import 'package:taskflow/core/storage/local_store.dart';
import 'package:taskflow/data/repositories/mock_repositories.dart';
import 'package:taskflow/data/repositories/offline_cache.dart';
import 'package:taskflow/domain/entities/entities.dart';
import 'package:taskflow/domain/entities/enums.dart';

import '../support/harness.dart';

void main() {
  group('project repository', () {
    late MockProjectRepository projects;
    late MockTaskRepository tasks;

    setUp(() {
      final source = testDataSource();
      final cache = OfflineCache(InMemoryLocalStore());
      projects = MockProjectRepository(source, cache);
      tasks = MockTaskRepository(source, cache);
    });

    test('lists the seeded projects for the organization', () async {
      final result = await projects.list(sessionFor());
      expect(result.length, 2);
      expect(
        result.map((p) => p.name),
        containsAll(['Website Relaunch', 'Mobile App v2']),
      );
    });

    test('task count is derived from live tasks, not the stored field', () async {
      final session = sessionFor();
      final before = (await projects.list(session)).firstWhere(
        (p) => p.id == Seed.websiteProjectId,
      );
      expect(before.taskCount, 6);

      await tasks.create(
        session,
        projectId: Seed.websiteProjectId,
        title: 'An extra task',
        description: '',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
      );

      final after = (await projects.list(session)).firstWhere(
        (p) => p.id == Seed.websiteProjectId,
      );
      expect(after.taskCount, 7);
    });

    test('creates a project scoped to the session organization', () async {
      final session = sessionFor();
      final created = await projects.create(
        session,
        name: 'New Initiative',
        description: 'Something fresh',
      );

      expect(created.orgId, Seed.nimbusOrgId);
      expect(created.taskCount, 0);
      expect((await projects.list(session)).map((p) => p.id),
          contains(created.id));
    });

    test('trims whitespace from names and descriptions', () async {
      final created = await projects.create(
        sessionFor(),
        name: '  Padded Name  ',
        description: '  Padded description  ',
      );
      expect(created.name, 'Padded Name');
      expect(created.description, 'Padded description');
    });

    test('updates an existing project', () async {
      final session = sessionFor();
      final original = await projects.byId(session, Seed.websiteProjectId);
      final updated = await projects.update(
        session,
        original.copyWith(name: 'Renamed Project'),
      );

      expect(updated.name, 'Renamed Project');
      expect(
        (await projects.byId(session, Seed.websiteProjectId)).name,
        'Renamed Project',
      );
    });

    test('a missing project reports not found', () async {
      await expectLater(
        projects.byId(sessionFor(), 'proj_missing'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('task repository', () {
    late MockTaskRepository tasks;

    setUp(() {
      tasks = MockTaskRepository(
        testDataSource(),
        OfflineCache(InMemoryLocalStore()),
      );
    });

    test('lists every task in the organization', () async {
      final result = await tasks.list(sessionFor());
      // 6 + 5 tasks across the two Nimbus projects.
      expect(result.length, 11);
    });

    test('lists tasks for a single project', () async {
      final result = await tasks.listForProject(
        sessionFor(),
        Seed.mobileProjectId,
      );
      expect(result.length, 5);
      expect(result.every((t) => t.projectId == Seed.mobileProjectId), isTrue);
    });

    test('creates a task and returns it in the list', () async {
      final session = sessionFor();
      final created = await tasks.create(
        session,
        projectId: Seed.websiteProjectId,
        title: 'Write release notes',
        description: 'Summarise the launch',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        assigneeId: Seed.marcusId,
        dueDate: DateTime(2026, 9, 1),
      );

      expect(created.title, 'Write release notes');
      expect(created.assigneeId, Seed.marcusId);
      expect((await tasks.list(session)).map((t) => t.id),
          contains(created.id));
    });

    test('creates an unassigned task when no assignee is given', () async {
      final created = await tasks.create(
        sessionFor(),
        projectId: Seed.websiteProjectId,
        title: 'Unowned task',
        description: '',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
      );
      expect(created.assigneeId, isNull);
      expect(created.isAssigned, isFalse);
    });

    test('updates status', () async {
      final session = sessionFor();
      final updated = await tasks.updateStatus(
        session,
        Seed.seoTaskId,
        TaskStatus.done,
      );
      expect(updated.status, TaskStatus.done);
      expect(
        (await tasks.byId(session, Seed.seoTaskId)).status,
        TaskStatus.done,
      );
    });

    test('updates priority', () async {
      final session = sessionFor();
      final updated = await tasks.updatePriority(
        session,
        Seed.seoTaskId,
        TaskPriority.urgent,
      );
      expect(updated.priority, TaskPriority.urgent);
    });

    test('deletes a task', () async {
      final session = sessionFor();
      await tasks.delete(session, Seed.seoTaskId);

      expect(
        (await tasks.list(session)).map((t) => t.id),
        isNot(contains(Seed.seoTaskId)),
      );
      await expectLater(
        tasks.byId(session, Seed.seoTaskId),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('a missing task reports not found', () async {
      await expectLater(
        tasks.byId(sessionFor(), 'task_missing'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('clearing a due date persists as null', () async {
      final session = sessionFor();
      final task = await tasks.byId(session, Seed.navTaskId);
      expect(task.dueDate, isNotNull);

      final updated = await tasks.update(
        session,
        task.copyWith(clearDueDate: true),
      );
      expect(updated.dueDate, isNull);
    });
  });

  group('members and comments', () {
    late MockOrgRepository org;
    late MockCommentRepository comments;

    setUp(() {
      final source = testDataSource();
      org = MockOrgRepository(source);
      comments = MockCommentRepository(source);
    });

    test('members are scoped to the organization', () async {
      final nimbus = await org.members(sessionFor());
      expect(nimbus.length, 3);
      expect(
        nimbus.map((m) => m.user.name),
        containsAll(['Ava Thompson', 'Marcus Lee', 'Priya Nair']),
      );

      final harborlight = await org.members(
        sessionFor(userId: Seed.danielId, orgId: Seed.harborlightOrgId),
      );
      expect(harborlight.length, 2);
    });

    test('roles come from org_members', () async {
      final members = await org.members(sessionFor());
      final ava = members.firstWhere((m) => m.user.id == Seed.avaId);
      final marcus = members.firstWhere((m) => m.user.id == Seed.marcusId);

      expect(ava.role, OrgRole.orgAdmin);
      expect(marcus.role, OrgRole.member);
    });

    test('reads the seeded comments for a task', () async {
      final result = await comments.forTask(sessionFor(), Seed.navTaskId);
      expect(result.length, 2);
      expect(result.first.createdAt.isBefore(result.last.createdAt), isTrue);
    });

    test('adds a comment authored by the session user', () async {
      final session = sessionFor();
      final created = await comments.add(
        session,
        Seed.navTaskId,
        'Looks good to me',
      );

      expect(created.authorId, session.userId);
      expect(
        (await comments.forTask(session, Seed.navTaskId)).length,
        3,
      );
    });

    test('rejects an empty comment', () async {
      await expectLater(
        comments.add(sessionFor(), Seed.navTaskId, '   '),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('notifications', () {
    test('are scoped to the signed-in user', () async {
      final repo = MockNotificationRepository(testDataSource());

      final marcus = await repo.list(sessionFor(userId: Seed.marcusId));
      expect(marcus.length, 1);
      expect(marcus.single.taskId, 'task_2004');

      final ava = await repo.list(sessionFor(userId: Seed.avaId));
      expect(ava, isEmpty);
    });

    test('assigning a task notifies the new assignee', () async {
      final source = testDataSource();
      final tasks = MockTaskRepository(
        source,
        OfflineCache(InMemoryLocalStore()),
      );
      final notifications = MockNotificationRepository(source);
      final session = sessionFor();

      final before = await notifications.list(
        sessionFor(userId: Seed.priyaId),
      );
      await tasks.assign(session, Seed.seoTaskId, Seed.priyaId);
      final after = await notifications.list(sessionFor(userId: Seed.priyaId));

      expect(after.length, before.length + 1);
      expect(after.first.taskId, Seed.seoTaskId);
      expect(after.first.read, isFalse);
    });

    test('marking read updates the record', () async {
      final source = testDataSource();
      final repo = MockNotificationRepository(source);
      final session = sessionFor(userId: Seed.marcusId);

      final unread = (await repo.list(session)).single;
      expect(unread.read, isFalse);

      await repo.markRead(session, unread.id);
      expect((await repo.list(session)).single.read, isTrue);
    });
  });

  group('error simulation', () {
    late DevSettings settings;
    late MockProjectRepository projects;
    late MockTaskRepository tasks;

    setUp(() {
      settings = const DevSettings();
      final source = testDataSource(devSettings: () => settings);
      final cache = OfflineCache(InMemoryLocalStore());
      projects = MockProjectRepository(source, cache);
      tasks = MockTaskRepository(source, cache);
    });

    test('timeout surfaces as a timeout exception', () async {
      settings = const DevSettings(failure: SimulatedFailure.timeout);
      await expectLater(
        projects.list(sessionFor()),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('server error surfaces as a server exception', () async {
      settings = const DevSettings(failure: SimulatedFailure.serverError);
      await expectLater(
        projects.list(sessionFor()),
        throwsA(isA<ServerException>()),
      );
    });

    test('not found affects single-item reads', () async {
      settings = const DevSettings(failure: SimulatedFailure.notFound);
      await expectLater(
        tasks.byId(sessionFor(), Seed.navTaskId),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('not found leaves list reads working', () async {
      settings = const DevSettings(failure: SimulatedFailure.notFound);
      expect(await projects.list(sessionFor()), isNotEmpty);
    });

    test('validation error affects writes but not reads', () async {
      settings = const DevSettings(failure: SimulatedFailure.validationError);

      expect(await projects.list(sessionFor()), isNotEmpty);
      await expectLater(
        projects.create(sessionFor(), name: 'Blocked', description: ''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('unauthorized surfaces so the refresh path can run', () async {
      settings = const DevSettings(failure: SimulatedFailure.unauthorized);
      await expectLater(
        projects.list(sessionFor()),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('offline behaviour', () {
    test('reads fall back to the cache and writes are blocked', () async {
      var settings = const DevSettings();
      final source = testDataSource(devSettings: () => settings);
      final store = InMemoryLocalStore();
      final cache = OfflineCache(store);
      final projects = MockProjectRepository(source, cache);
      final session = sessionFor();

      // Warm the cache while online.
      final online = await projects.list(session);
      expect(online, isNotEmpty);

      settings = const DevSettings(offline: true);

      final cached = await projects.list(session);
      expect(cached.map((p) => p.id), online.map((p) => p.id));

      await expectLater(
        projects.create(session, name: 'While offline', description: ''),
        throwsA(isA<OfflineException>()),
      );
    });

    test('a cold cache offline surfaces the network error', () async {
      final source = testDataSource(
        devSettings: () => const DevSettings(offline: true),
      );
      final projects = MockProjectRepository(
        source,
        OfflineCache(InMemoryLocalStore()),
      );

      await expectLater(
        projects.list(sessionFor()),
        throwsA(isA<NetworkException>()),
      );
    });

    test('cachedAt reports when the snapshot was written', () async {
      final source = testDataSource();
      final projects = MockProjectRepository(
        source,
        OfflineCache(InMemoryLocalStore()),
      );
      final session = sessionFor();

      expect(projects.cachedAt(session.orgId), isNull);
      await projects.list(session);
      expect(projects.cachedAt(session.orgId), isNotNull);
    });

    test('the cache is scoped per organization', () async {
      final source = testDataSource();
      final projects = MockProjectRepository(
        source,
        OfflineCache(InMemoryLocalStore()),
      );

      await projects.list(sessionFor());

      expect(projects.cachedAt(Seed.nimbusOrgId), isNotNull);
      expect(projects.cachedAt(Seed.harborlightOrgId), isNull);
    });
  });

  group('TaskStats', () {
    test('counts by status and totals', () {
      final now = DateTime(2026, 2, 1);
      final stats = TaskStats.from([
        Task(
          id: '1',
          projectId: 'p',
          title: 'a',
          description: '',
          status: TaskStatus.done,
          priority: TaskPriority.low,
          createdAt: now,
        ),
        Task(
          id: '2',
          projectId: 'p',
          title: 'b',
          description: '',
          status: TaskStatus.todo,
          priority: TaskPriority.low,
          createdAt: now,
        ),
      ], now);

      expect(stats.total, 2);
      expect(stats.completed, 1);
      expect(stats.open, 1);
      expect(stats.completionRate, 0.5);
    });

    test('counts overdue only for open tasks', () {
      final now = DateTime(2026, 2, 10);
      final stats = TaskStats.from([
        Task(
          id: 'overdue',
          projectId: 'p',
          title: 'a',
          description: '',
          status: TaskStatus.todo,
          priority: TaskPriority.low,
          dueDate: DateTime(2026, 2, 1),
          createdAt: now,
        ),
        Task(
          id: 'doneButLate',
          projectId: 'p',
          title: 'b',
          description: '',
          status: TaskStatus.done,
          priority: TaskPriority.low,
          dueDate: DateTime(2026, 2, 1),
          createdAt: now,
        ),
      ], now);

      expect(stats.overdue, 1);
    });

    test('an empty list yields a zero completion rate, not NaN', () {
      final stats = TaskStats.from(const [], DateTime(2026, 1, 1));
      expect(stats.total, 0);
      expect(stats.completionRate, 0);
    });
  });
}
