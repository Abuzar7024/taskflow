import '../../core/errors/app_exception.dart';
import '../../core/storage/local_store.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/permissions.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/mock_data_source.dart';
import '../models/models.dart';
import 'offline_cache.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository(this._source);

  final MockDataSource _source;

  @override
  Future<({Session session, AuthTokens tokens})> login({
    required String email,
    required String password,
  }) {
    return _source.login(email: email, password: password);
  }

  @override
  Future<({Session session, AuthTokens tokens})> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _source.register(name: name, email: email, password: password);
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) =>
      _source.refresh(refreshToken);
}

class MockProjectRepository implements ProjectRepository {
  const MockProjectRepository(this._source, this._cache);

  final MockDataSource _source;
  final OfflineCache _cache;

  @override
  Future<List<Project>> list(Session session) async {
    try {
      final projects = await _source.projectsOf(session.orgId);
      await _cache.write(
        StorageKeys.projects(session.orgId),
        projects,
        (p) => p.toJson(),
      );
      return projects;
    } on AppException {
      // Reads fall back to the cache so offline users keep seeing their data.
      final cached = _cachedProjects(session.orgId);
      if (cached != null) return cached.items;
      rethrow;
    }
  }

  @override
  Future<Project> byId(Session session, String projectId) async {
    final project = await _source.projectById(projectId);
    Permissions.requireSameOrg(session, project.orgId);
    return project;
  }

  @override
  Future<Project> create(
    Session session, {
    required String name,
    required String description,
  }) {
    return _source.createProject(
      orgId: session.orgId,
      name: name,
      description: description,
    );
  }

  @override
  Future<Project> update(Session session, Project project) {
    Permissions.requireSameOrg(session, project.orgId);
    return _source.updateProject(project);
  }

  @override
  Future<void> delete(Session session, String projectId) async {
    Permissions.requireAdmin(session, 'delete projects');
    final project = await _source.projectById(projectId);
    Permissions.requireSameOrg(session, project.orgId);
    await _source.deleteProject(projectId);
  }

  CachedList<Project>? _cachedProjects(String orgId) {
    return _cache.read(
      StorageKeys.projects(orgId),
      (json) => ProjectMapper.fromJson(json),
    );
  }

  /// Exposed so the UI can show when cached data was last refreshed.
  DateTime? cachedAt(String orgId) => _cachedProjects(orgId)?.cachedAt;
}

class MockTaskRepository implements TaskRepository {
  const MockTaskRepository(this._source, this._cache);

  final MockDataSource _source;
  final OfflineCache _cache;

  @override
  Future<List<Task>> list(Session session) async {
    try {
      final tasks = await _source.tasksOf(session.orgId);
      await _cache.write(
        StorageKeys.tasks(session.orgId),
        tasks,
        (t) => t.toJson(),
      );
      return tasks;
    } on AppException {
      final cached = _cachedTasks(session.orgId);
      if (cached != null) return cached.items;
      rethrow;
    }
  }

  @override
  Future<List<Task>> listForProject(Session session, String projectId) async {
    await _requireProjectInOrg(session, projectId);
    return _source.tasksOfProject(projectId);
  }

  @override
  Future<Task> byId(Session session, String taskId) async {
    final task = await _source.taskById(taskId);
    await _requireProjectInOrg(session, task.projectId);
    return task;
  }

  @override
  Future<Task> create(
    Session session, {
    required String projectId,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    String? assigneeId,
    DateTime? dueDate,
  }) async {
    await _requireProjectInOrg(session, projectId);
    await _requireAssigneeInOrg(session, assigneeId);
    return _source.createTask(
      projectId: projectId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      dueDate: dueDate,
    );
  }

  @override
  Future<Task> update(Session session, Task task) async {
    await _requireProjectInOrg(session, task.projectId);
    await _requireAssigneeInOrg(session, task.assigneeId);
    return _source.updateTask(task);
  }

  @override
  Future<void> delete(Session session, String taskId) async {
    final task = await byId(session, taskId);
    await _source.deleteTask(task.id);
  }

  @override
  Future<Task> updateStatus(
    Session session,
    String taskId,
    TaskStatus status,
  ) async {
    final task = await byId(session, taskId);
    return _source.updateTask(task.copyWith(status: status));
  }

  @override
  Future<Task> updatePriority(
    Session session,
    String taskId,
    TaskPriority priority,
  ) async {
    final task = await byId(session, taskId);
    return _source.updateTask(task.copyWith(priority: priority));
  }

  @override
  Future<Task> assign(
    Session session,
    String taskId,
    String? assigneeId,
  ) async {
    final task = await byId(session, taskId);
    await _requireAssigneeInOrg(session, assigneeId);
    return _source.updateTask(
      assigneeId == null
          ? task.copyWith(clearAssignee: true)
          : task.copyWith(assigneeId: assigneeId),
    );
  }

  /// Tenant isolation for task operations: the owning project must belong to
  /// the caller's organization.
  Future<void> _requireProjectInOrg(Session session, String projectId) async {
    final project = await _source.projectById(projectId);
    Permissions.requireSameOrg(session, project.orgId);
  }

  /// Rejects an assignee who is not a member of the caller's organization,
  /// even if the id was supplied directly rather than picked from the list.
  Future<void> _requireAssigneeInOrg(
    Session session,
    String? assigneeId,
  ) async {
    if (assigneeId == null) return;
    final isMember = await _source.isMemberOfOrg(assigneeId, session.orgId);
    if (!isMember) {
      throw const ForbiddenException(
        'You can only assign people from your organization.',
      );
    }
  }

  CachedList<Task>? _cachedTasks(String orgId) {
    return _cache.read(StorageKeys.tasks(orgId), TaskMapper.fromJson);
  }

  DateTime? cachedAt(String orgId) => _cachedTasks(orgId)?.cachedAt;
}

class MockOrgRepository implements OrgRepository {
  const MockOrgRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<OrgMember>> members(Session session) =>
      _source.membersOf(session.orgId);
}

class MockCommentRepository implements CommentRepository {
  const MockCommentRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<Comment>> forTask(Session session, String taskId) async {
    await _requireTaskInOrg(session, taskId);
    return _source.commentsOf(taskId);
  }

  @override
  Future<Comment> add(Session session, String taskId, String body) async {
    if (body.trim().isEmpty) {
      throw const ValidationException('Write something before posting.', {
        'body': 'Comment cannot be empty.',
      });
    }
    await _requireTaskInOrg(session, taskId);
    return _source.addComment(
      taskId: taskId,
      authorId: session.userId,
      body: body,
    );
  }

  Future<void> _requireTaskInOrg(Session session, String taskId) async {
    final task = await _source.taskById(taskId);
    final project = await _source.projectById(task.projectId);
    Permissions.requireSameOrg(session, project.orgId);
  }
}

class MockNotificationRepository implements NotificationRepository {
  const MockNotificationRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<AppNotification>> list(Session session) =>
      _source.notificationsOf(session.userId);

  @override
  Future<void> markRead(Session session, String notificationId) =>
      _source.markNotificationRead(notificationId);

  @override
  Future<void> markAllRead(Session session) =>
      _source.markAllNotificationsRead(session.userId);
}

class MockUserRepository implements UserRepository {
  const MockUserRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<User>> all() => _source.allUsers();
}
