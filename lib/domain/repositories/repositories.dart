import '../entities/entities.dart';
import '../entities/enums.dart';
import '../entities/session.dart';

/// Repository contracts.
///
/// The presentation layer depends only on these, so the mock implementations
/// can be swapped for HTTP-backed ones without touching UI or providers.

abstract interface class AuthRepository {
  Future<({Session session, AuthTokens tokens})> login({
    required String email,
    required String password,
  });

  Future<({Session session, AuthTokens tokens})> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthTokens> refresh(String refreshToken);
}

/// Data read through this repository is always scoped to [Session.orgId]; the
/// implementation rejects any request that reaches outside it.
abstract interface class ProjectRepository {
  Future<List<Project>> list(Session session);
  Future<Project> byId(Session session, String projectId);
  Future<Project> create(
    Session session, {
    required String name,
    required String description,
  });
  Future<Project> update(Session session, Project project);

  /// Admin-only. Throws [ForbiddenException] for a member, regardless of UI.
  Future<void> delete(Session session, String projectId);
}

abstract interface class TaskRepository {
  Future<List<Task>> list(Session session);
  Future<List<Task>> listForProject(Session session, String projectId);
  Future<Task> byId(Session session, String taskId);

  Future<Task> create(
    Session session, {
    required String projectId,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    String? assigneeId,
    DateTime? dueDate,
  });

  Future<Task> update(Session session, Task task);
  Future<void> delete(Session session, String taskId);

  Future<Task> updateStatus(Session session, String taskId, TaskStatus status);
  Future<Task> updatePriority(
    Session session,
    String taskId,
    TaskPriority priority,
  );

  /// Passing a null [assigneeId] unassigns. A user outside the session's
  /// organization is rejected with [ForbiddenException].
  Future<Task> assign(Session session, String taskId, String? assigneeId);
}

abstract interface class OrgRepository {
  Future<List<OrgMember>> members(Session session);
}

abstract interface class CommentRepository {
  Future<List<Comment>> forTask(Session session, String taskId);
  Future<Comment> add(Session session, String taskId, String body);
}

abstract interface class NotificationRepository {
  Future<List<AppNotification>> list(Session session);
  Future<void> markRead(Session session, String notificationId);
  Future<void> markAllRead(Session session);
}

/// Read-only directory of users referenced by tasks and comments.
abstract interface class UserRepository {
  Future<List<User>> all();
}
