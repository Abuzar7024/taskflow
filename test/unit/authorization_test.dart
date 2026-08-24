import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/errors/app_exception.dart';
import 'package:taskflow/core/storage/local_store.dart';
import 'package:taskflow/data/repositories/mock_repositories.dart';
import 'package:taskflow/data/repositories/offline_cache.dart';
import 'package:taskflow/domain/entities/enums.dart';
import 'package:taskflow/domain/entities/permissions.dart';

import '../support/harness.dart';

/// These tests call the repositories directly, bypassing the UI entirely, to
/// prove that authorization is enforced in business logic rather than by
/// hiding buttons.
void main() {
  late MockProjectRepository projects;
  late MockTaskRepository tasks;

  setUp(() {
    final source = testDataSource();
    final cache = OfflineCache(InMemoryLocalStore());
    projects = MockProjectRepository(source, cache);
    tasks = MockTaskRepository(source, cache);
  });

  group('Permissions', () {
    test('only an admin may delete projects', () {
      expect(Permissions.canDeleteProject(sessionFor()), isTrue);
      expect(
        Permissions.canDeleteProject(sessionFor(role: OrgRole.member)),
        isFalse,
      );
    });

    test('only an admin may manage members', () {
      expect(Permissions.canManageMembers(sessionFor()), isTrue);
      expect(
        Permissions.canManageMembers(sessionFor(role: OrgRole.member)),
        isFalse,
      );
    });

    test('requireAdmin throws for a member', () {
      expect(
        () => Permissions.requireAdmin(
          sessionFor(role: OrgRole.member),
          'delete projects',
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('requireSameOrg throws across organizations', () {
      expect(
        () => Permissions.requireSameOrg(sessionFor(), Seed.harborlightOrgId),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('project deletion', () {
    test('an admin can delete a project in their org', () async {
      final session = sessionFor(role: OrgRole.orgAdmin);
      await projects.delete(session, Seed.websiteProjectId);

      final remaining = await projects.list(session);
      expect(
        remaining.map((p) => p.id),
        isNot(contains(Seed.websiteProjectId)),
      );
    });

    test('a member calling delete directly is rejected', () async {
      final session = sessionFor(userId: Seed.marcusId, role: OrgRole.member);

      await expectLater(
        projects.delete(session, Seed.websiteProjectId),
        throwsA(isA<ForbiddenException>()),
      );

      // And the project must survive the rejected attempt.
      final remaining = await projects.list(session);
      expect(remaining.map((p) => p.id), contains(Seed.websiteProjectId));
    });

    test('an admin cannot delete another organization\'s project', () async {
      final session = sessionFor(role: OrgRole.orgAdmin);

      await expectLater(
        projects.delete(session, Seed.onboardingProjectId),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('deleting a project cascades to its tasks', () async {
      final session = sessionFor();
      await projects.delete(session, Seed.websiteProjectId);

      final remaining = await tasks.list(session);
      expect(
        remaining.where((t) => t.projectId == Seed.websiteProjectId),
        isEmpty,
      );
    });
  });

  group('tenant isolation', () {
    test('a project list contains only the session organization', () async {
      final nimbus = await projects.list(sessionFor());
      expect(nimbus.every((p) => p.orgId == Seed.nimbusOrgId), isTrue);

      final harborlight = await projects.list(
        sessionFor(userId: Seed.danielId, orgId: Seed.harborlightOrgId),
      );
      expect(harborlight.every((p) => p.orgId == Seed.harborlightOrgId), isTrue);
    });

    test('reading another org\'s project by id is rejected', () async {
      await expectLater(
        projects.byId(sessionFor(), Seed.onboardingProjectId),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('reading another org\'s task by id is rejected', () async {
      await expectLater(
        tasks.byId(sessionFor(), Seed.onboardingTaskId),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('a task list contains only the session organization', () async {
      final result = await tasks.list(sessionFor());
      expect(
        result.every(
          (t) => t.projectId != Seed.onboardingProjectId,
        ),
        isTrue,
      );
    });

    test('creating a task in another org\'s project is rejected', () async {
      await expectLater(
        tasks.create(
          sessionFor(),
          projectId: Seed.onboardingProjectId,
          title: 'Sneaky cross-tenant task',
          description: '',
          status: TaskStatus.todo,
          priority: TaskPriority.low,
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('updating another org\'s task is rejected', () async {
      final foreign = await tasks.byId(
        sessionFor(userId: Seed.danielId, orgId: Seed.harborlightOrgId),
        Seed.onboardingTaskId,
      );

      await expectLater(
        tasks.update(sessionFor(), foreign.copyWith(title: 'Hijacked')),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('deleting another org\'s task is rejected', () async {
      await expectLater(
        tasks.delete(sessionFor(), Seed.onboardingTaskId),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('assignment validation', () {
    test('assigning a member of the same org succeeds', () async {
      final session = sessionFor();
      final updated = await tasks.assign(
        session,
        Seed.seoTaskId,
        Seed.marcusId,
      );
      expect(updated.assigneeId, Seed.marcusId);
    });

    test('assigning a user from another org is rejected', () async {
      await expectLater(
        tasks.assign(sessionFor(), Seed.seoTaskId, Seed.elenaId),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('assigning an unknown user id is rejected', () async {
      await expectLater(
        tasks.assign(sessionFor(), Seed.seoTaskId, 'user_does_not_exist'),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('a rejected assignment leaves the task unchanged', () async {
      final session = sessionFor();
      final before = await tasks.byId(session, Seed.seoTaskId);

      await expectLater(
        tasks.assign(session, Seed.seoTaskId, Seed.elenaId),
        throwsA(isA<ForbiddenException>()),
      );

      final after = await tasks.byId(session, Seed.seoTaskId);
      expect(after.assigneeId, before.assigneeId);
    });

    test('unassigning is always allowed', () async {
      final session = sessionFor();
      final updated = await tasks.assign(session, Seed.navTaskId, null);
      expect(updated.assigneeId, isNull);
    });

    test('creating a task with an out-of-org assignee is rejected', () async {
      await expectLater(
        tasks.create(
          sessionFor(),
          projectId: Seed.websiteProjectId,
          title: 'Task with a foreign assignee',
          description: '',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
          assigneeId: Seed.elenaId,
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('updating a task to an out-of-org assignee is rejected', () async {
      final session = sessionFor();
      final task = await tasks.byId(session, Seed.seoTaskId);

      await expectLater(
        tasks.update(session, task.copyWith(assigneeId: Seed.elenaId)),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });
}
