import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import '../../domain/entities/task_filter.dart';
import '../auth/auth_controller.dart';
import '../providers.dart';

/// Every task in the signed-in organization.
final tasksProvider = FutureProvider.autoDispose<List<Task>>((ref) {
  final session = ref.watch(sessionProvider);
  final repository = ref.watch(taskRepositoryProvider);
  return authenticatedRead(ref, () => repository.list(session));
});

final projectTasksProvider = FutureProvider.autoDispose
    .family<List<Task>, String>((ref, projectId) {
      final session = ref.watch(sessionProvider);
      final repository = ref.watch(taskRepositoryProvider);
      return authenticatedRead(
        ref,
        () => repository.listForProject(session, projectId),
      );
    });

final taskByIdProvider = FutureProvider.autoDispose.family<Task, String>((
  ref,
  taskId,
) {
  final session = ref.watch(sessionProvider);
  final repository = ref.watch(taskRepositoryProvider);
  return authenticatedRead(ref, () => repository.byId(session, taskId));
});

final taskCommentsProvider = FutureProvider.autoDispose
    .family<List<Comment>, String>((ref, taskId) {
      final session = ref.watch(sessionProvider);
      final repository = ref.watch(commentRepositoryProvider);
      return authenticatedRead(ref, () => repository.forTask(session, taskId));
    });

/// Members of the signed-in organization — the only users who may be assigned.
final orgMembersProvider = FutureProvider.autoDispose<List<OrgMember>>((ref) {
  final session = ref.watch(sessionProvider);
  final repository = ref.watch(orgRepositoryProvider);
  return authenticatedRead(ref, () => repository.members(session));
});

/// Lookup of every user referenced by tasks and comments, keyed by id.
final userDirectoryProvider = FutureProvider.autoDispose<Map<String, User>>((
  ref,
) async {
  final repository = ref.watch(userRepositoryProvider);
  final users = await authenticatedRead(ref, repository.all);
  return {for (final user in users) user.id: user};
});

/// The active filter for the task list. Held per-screen-family so the project
/// task list and the global task list filter independently.
final taskFilterProvider = StateProvider.autoDispose
    .family<TaskFilter, String>((ref, scope) => const TaskFilter());

/// Filter scope keys.
abstract final class FilterScopes {
  static const allTasks = 'all';

  static String project(String projectId) => 'project:$projectId';
}

final tasksCachedAtProvider = Provider.autoDispose<DateTime?>((ref) {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) return null;
  return ref.watch(taskRepositoryProvider).cachedAt(session.orgId);
});
