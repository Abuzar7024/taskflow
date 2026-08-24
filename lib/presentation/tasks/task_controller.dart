import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../auth/auth_controller.dart';
import '../mutation_result.dart';
import '../notifications/notification_providers.dart';
import '../projects/project_providers.dart';
import '../providers.dart';
import 'task_providers.dart';

/// Create/update/delete for tasks plus the quick status, priority and
/// assignment actions used from list and detail screens.
class TaskController extends StateNotifier<bool> {
  TaskController(this._ref) : super(false);

  final Ref _ref;

  Future<MutationResult<Task>> create({
    required String projectId,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    String? assigneeId,
    DateTime? dueDate,
  }) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref
          .read(taskRepositoryProvider)
          .create(
            session,
            projectId: projectId,
            title: title,
            description: description,
            status: status,
            priority: priority,
            assigneeId: assigneeId,
            dueDate: dueDate,
          );
    }, projectId: projectId);
  }

  Future<MutationResult<Task>> update(Task task) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref.read(taskRepositoryProvider).update(session, task);
    }, projectId: task.projectId, taskId: task.id);
  }

  Future<MutationResult<void>> delete(Task task) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref.read(taskRepositoryProvider).delete(session, task.id);
    }, projectId: task.projectId, taskId: task.id);
  }

  Future<MutationResult<Task>> setStatus(Task task, TaskStatus status) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref
          .read(taskRepositoryProvider)
          .updateStatus(session, task.id, status);
    }, projectId: task.projectId, taskId: task.id);
  }

  Future<MutationResult<Task>> setPriority(Task task, TaskPriority priority) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref
          .read(taskRepositoryProvider)
          .updatePriority(session, task.id, priority);
    }, projectId: task.projectId, taskId: task.id);
  }

  /// Passing a null [assigneeId] unassigns the task.
  Future<MutationResult<Task>> assign(Task task, String? assigneeId) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref
          .read(taskRepositoryProvider)
          .assign(session, task.id, assigneeId);
    }, projectId: task.projectId, taskId: task.id);
  }

  Future<MutationResult<Comment>> addComment(Task task, String body) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref.read(commentRepositoryProvider).add(session, task.id, body);
    }, taskId: task.id, invalidateComments: true);
  }

  Future<MutationResult<T>> _run<T>(
    Future<T> Function() action, {
    String? projectId,
    String? taskId,
    bool invalidateComments = false,
  }) async {
    if (state) {
      return const MutationFailure('Please wait for the current change.');
    }
    state = true;
    try {
      await _ref.read(authControllerProvider.notifier).ensureValidAccessToken();
      final value = await action();
      _invalidate(
        projectId: projectId,
        taskId: taskId,
        invalidateComments: invalidateComments,
      );
      return MutationSuccess(value);
    } on ValidationException catch (e) {
      return MutationFailure(e.message, e.fieldErrors);
    } on UnauthorizedException catch (e) {
      await _ref.read(authControllerProvider.notifier).handleUnauthorized();
      return MutationFailure(e.message);
    } on AppException catch (e) {
      return MutationFailure(e.message);
    } finally {
      state = false;
    }
  }

  /// Refreshes every view a task change can affect: the task lists, the
  /// owning project's derived task count, and the notification badge.
  void _invalidate({
    String? projectId,
    String? taskId,
    bool invalidateComments = false,
  }) {
    _ref.invalidate(tasksProvider);
    _ref.invalidate(projectsProvider);
    _ref.invalidate(notificationsProvider);
    if (projectId != null) {
      _ref.invalidate(projectTasksProvider(projectId));
      _ref.invalidate(projectByIdProvider(projectId));
    }
    if (taskId != null) {
      _ref.invalidate(taskByIdProvider(taskId));
      if (invalidateComments) _ref.invalidate(taskCommentsProvider(taskId));
    }
  }
}

final taskControllerProvider = StateNotifierProvider<TaskController, bool>((
  ref,
) {
  return TaskController(ref);
});
