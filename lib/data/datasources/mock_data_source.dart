import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/constants/dev_settings.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/session.dart';
import '../models/models.dart';

/// The bundled JSON acting as the backend.
///
/// It owns an in-memory copy of the seed data and applies mutations to it, so
/// changes survive navigation for the lifetime of the process (a real backend
/// would persist them). Reads and writes go through [_simulate], which applies
/// the artificial latency and any failure a reviewer has switched on.
class MockDataSource {
  MockDataSource({
    DevSettings Function()? devSettings,
    Future<String> Function()? loadAsset,
    this.latency = const Duration(milliseconds: 450),
  }) : _devSettings = devSettings ?? (() => const DevSettings()),
       _loadAsset = loadAsset ?? _loadFromBundle;

  static const assetPath = 'assets/data/mock_data.json';

  final DevSettings Function() _devSettings;
  final Future<String> Function() _loadAsset;
  final Duration latency;

  final List<Organization> _organizations = [];
  final List<User> _users = [];
  final List<({String orgId, String userId, OrgRole role})> _memberships = [];
  final List<Project> _projects = [];
  final List<Task> _tasks = [];
  final List<Comment> _comments = [];
  final List<AppNotification> _notifications = [];
  final List<MockCredential> _credentials = [];
  late MockLoginResponse _loginResponse;

  bool _loaded = false;
  Future<void>? _loading;
  var _idCounter = 0;

  static Future<String> _loadFromBundle() =>
      rootBundle.loadString(assetPath);

  /// Parses the asset once. Concurrent callers await the same future rather
  /// than each kicking off a parse.
  Future<void> _ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    final raw = await _loadAsset();
    final json = jsonDecode(raw) as Map<String, dynamic>;

    _organizations
      ..clear()
      ..addAll(
        (json['organizations'] as List).cast<Map<String, dynamic>>().map(
          OrganizationMapper.fromJson,
        ),
      );
    _users
      ..clear()
      ..addAll(
        (json['users'] as List).cast<Map<String, dynamic>>().map(
          UserMapper.fromJson,
        ),
      );
    _memberships
      ..clear()
      ..addAll(
        (json['org_members'] as List).cast<Map<String, dynamic>>().map(
          (m) => (
            orgId: m['org_id'] as String,
            userId: m['user_id'] as String,
            role: OrgRole.fromWire(m['role'] as String),
          ),
        ),
      );
    _projects
      ..clear()
      ..addAll(
        (json['projects'] as List).cast<Map<String, dynamic>>().map(
          (p) => ProjectMapper.fromJson(p),
        ),
      );
    _tasks
      ..clear()
      ..addAll(
        (json['tasks'] as List).cast<Map<String, dynamic>>().map(
          TaskMapper.fromJson,
        ),
      );
    _comments
      ..clear()
      ..addAll(
        (json['comments'] as List).cast<Map<String, dynamic>>().map(
          CommentMapper.fromJson,
        ),
      );
    _notifications
      ..clear()
      ..addAll(
        (json['notifications'] as List).cast<Map<String, dynamic>>().map(
          NotificationMapper.fromJson,
        ),
      );

    final auth = json['auth_mock'] as Map<String, dynamic>;
    _credentials
      ..clear()
      ..addAll(
        (auth['test_credentials'] as List).cast<Map<String, dynamic>>().map(
          MockCredential.fromJson,
        ),
      );
    _loginResponse = MockLoginResponse.fromJson(
      auth['mock_login_response'] as Map<String, dynamic>,
    );

    _loaded = true;
  }

  /// Applies latency and the configured simulated failure, then runs [action].
  ///
  /// [isWrite] marks operations that must be blocked while offline; reads are
  /// allowed to fall through so the repository can serve them from cache.
  Future<T> _simulate<T>(
    FutureOr<T> Function() action, {
    bool isWrite = false,
    bool affectedByNotFound = false,
  }) async {
    final dev = _devSettings();

    if (dev.offline) {
      throw isWrite ? const OfflineException() : const NetworkException();
    }

    final delay = dev.slowNetwork ? latency * 6 : latency;
    // Skip the timer entirely at zero latency: tests configure it that way,
    // and a pending zero-duration timer would outlive the test's fake clock.
    if (delay > Duration.zero) await Future<void>.delayed(delay);

    switch (dev.failure) {
      case SimulatedFailure.timeout:
        throw const TimeoutException();
      case SimulatedFailure.serverError:
        throw const ServerException();
      case SimulatedFailure.unauthorized:
        throw const UnauthorizedException();
      case SimulatedFailure.validationError:
        if (isWrite) {
          throw const ValidationException(
            'The server rejected this change.',
            {'title': 'This value was rejected by the server.'},
          );
        }
      case SimulatedFailure.notFound:
        if (affectedByNotFound) throw const NotFoundException();
      case SimulatedFailure.none:
        break;
    }

    await _ensureLoaded();
    return action();
  }

  String _nextId(String prefix) => '${prefix}_local_${++_idCounter}';

  // --- Auth -------------------------------------------------------------

  /// Verifies credentials against `auth_mock.test_credentials`.
  Future<({Session session, AuthTokens tokens})> login({
    required String email,
    required String password,
  }) {
    return _simulate(() {
      final normalized = email.trim().toLowerCase();
      final credential = _credentials
          .where((c) => c.email.toLowerCase() == normalized)
          .firstOrNull;

      if (credential == null || credential.password != password) {
        throw const InvalidCredentialsException();
      }

      final user = _users.firstWhere((u) => u.email.toLowerCase() == normalized);
      return (
        session: _sessionFor(user, credential.orgId, credential.role),
        tokens: _issueTokens(),
      );
    });
  }

  /// Simulates registration: creates an in-memory user, attaches them to an
  /// organization as a member, and signs them in.
  Future<({Session session, AuthTokens tokens})> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _simulate(isWrite: true, () {
      final normalized = email.trim().toLowerCase();
      if (_users.any((u) => u.email.toLowerCase() == normalized)) {
        throw const ValidationException('That email is already registered.', {
          'email': 'That email is already registered.',
        });
      }

      // New sign-ups join the first organization as a plain member; the mock
      // data has no invitation flow to model anything richer.
      final orgId = _organizations.first.id;
      final user = User(
        id: _nextId('user'),
        name: name.trim(),
        email: normalized,
      );

      _users.add(user);
      _memberships.add((orgId: orgId, userId: user.id, role: OrgRole.member));
      _credentials.add(
        MockCredential(
          email: normalized,
          password: password,
          orgId: orgId,
          role: OrgRole.member,
        ),
      );

      return (
        session: _sessionFor(user, orgId, OrgRole.member),
        tokens: _issueTokens(),
      );
    });
  }

  /// Exchanges a refresh token for a fresh pair. The mock backend accepts any
  /// non-empty refresh token it previously issued.
  Future<AuthTokens> refresh(String refreshToken) {
    return _simulate(() {
      if (refreshToken.isEmpty ||
          refreshToken != _loginResponse.refreshToken) {
        throw const UnauthorizedException();
      }
      return _issueTokens();
    });
  }

  AuthTokens _issueTokens() {
    return AuthTokens.fromLifetimes(
      accessToken: _loginResponse.accessToken,
      refreshToken: _loginResponse.refreshToken,
      accessTokenLifetimeSeconds: _loginResponse.accessTokenLifetimeSeconds,
      refreshTokenLifetimeSeconds: _loginResponse.refreshTokenLifetimeSeconds,
      issuedAt: DateTime.now(),
    );
  }

  Session _sessionFor(User user, String orgId, OrgRole role) {
    final org = _organizations.firstWhere((o) => o.id == orgId);
    return Session(
      userId: user.id,
      name: user.name,
      email: user.email,
      orgId: org.id,
      orgName: org.name,
      role: role,
      avatarUrl: user.avatarUrl,
    );
  }

  /// The seeded credentials, used by the demo-account picker on the login
  /// screen so that no email or password is written into a widget.
  Future<List<MockCredential>> testCredentials() async {
    await _ensureLoaded();
    return List.unmodifiable(_credentials);
  }

  /// The organization new registrations are attached to.
  Future<String?> defaultOrganizationName() async {
    await _ensureLoaded();
    return _organizations.firstOrNull?.name;
  }

  // --- Organization members --------------------------------------------

  Future<List<OrgMember>> membersOf(String orgId) {
    return _simulate(() => _membersOfSync(orgId));
  }

  List<OrgMember> _membersOfSync(String orgId) {
    return _memberships.where((m) => m.orgId == orgId).map((m) {
        final user = _users.firstWhere((u) => u.id == m.userId);
        return OrgMember(user: user, orgId: m.orgId, role: m.role);
      }).toList()
      ..sort((a, b) => a.user.name.compareTo(b.user.name));
  }

  // --- Projects ---------------------------------------------------------

  Future<List<Project>> projectsOf(String orgId) {
    return _simulate(() {
      return _projects.where((p) => p.orgId == orgId).map(_withTaskCount).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<Project> projectById(String id) {
    return _simulate(affectedByNotFound: true, () {
      final project = _projects.where((p) => p.id == id).firstOrNull;
      if (project == null) {
        throw const NotFoundException('That project no longer exists.');
      }
      return _withTaskCount(project);
    });
  }

  Project _withTaskCount(Project project) {
    final count = _tasks.where((t) => t.projectId == project.id).length;
    return project.copyWith(taskCount: count);
  }

  Future<Project> createProject({
    required String orgId,
    required String name,
    required String description,
  }) {
    return _simulate(isWrite: true, () {
      final project = Project(
        id: _nextId('proj'),
        orgId: orgId,
        name: name.trim(),
        description: description.trim(),
        status: ProjectStatus.active,
        createdAt: DateTime.now(),
        taskCount: 0,
      );
      _projects.add(project);
      return project;
    });
  }

  Future<Project> updateProject(Project project) {
    return _simulate(isWrite: true, () {
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index == -1) {
        throw const NotFoundException('That project no longer exists.');
      }
      _projects[index] = project;
      return _withTaskCount(project);
    });
  }

  /// Deleting a project also removes its tasks and their comments, mirroring
  /// what a backend cascade would do.
  Future<void> deleteProject(String id) {
    return _simulate(isWrite: true, () {
      final index = _projects.indexWhere((p) => p.id == id);
      if (index == -1) {
        throw const NotFoundException('That project no longer exists.');
      }
      final taskIds = _tasks
          .where((t) => t.projectId == id)
          .map((t) => t.id)
          .toSet();
      _projects.removeAt(index);
      _tasks.removeWhere((t) => t.projectId == id);
      _comments.removeWhere((c) => taskIds.contains(c.taskId));
      _notifications.removeWhere(
        (n) => n.taskId != null && taskIds.contains(n.taskId),
      );
    });
  }

  // --- Tasks ------------------------------------------------------------

  /// All tasks for an organization, resolved through its projects.
  Future<List<Task>> tasksOf(String orgId) {
    return _simulate(() {
      final projectIds = _projects
          .where((p) => p.orgId == orgId)
          .map((p) => p.id)
          .toSet();
      return _tasks.where((t) => projectIds.contains(t.projectId)).toList()
        ..sort(_byPriorityThenDueDate);
    });
  }

  Future<List<Task>> tasksOfProject(String projectId) {
    return _simulate(() {
      return _tasks.where((t) => t.projectId == projectId).toList()
        ..sort(_byPriorityThenDueDate);
    });
  }

  Future<Task> taskById(String id) {
    return _simulate(affectedByNotFound: true, () {
      final task = _tasks.where((t) => t.id == id).firstOrNull;
      if (task == null) {
        throw const NotFoundException('That task no longer exists.');
      }
      return task;
    });
  }

  static int _byPriorityThenDueDate(Task a, Task b) {
    final byPriority = b.priority.weight.compareTo(a.priority.weight);
    if (byPriority != 0) return byPriority;
    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue == null && bDue == null) return a.createdAt.compareTo(b.createdAt);
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  Future<Task> createTask({
    required String projectId,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    String? assigneeId,
    DateTime? dueDate,
  }) {
    return _simulate(isWrite: true, () {
      if (!_projects.any((p) => p.id == projectId)) {
        throw const NotFoundException('That project no longer exists.');
      }
      final task = Task(
        id: _nextId('task'),
        projectId: projectId,
        title: title.trim(),
        description: description.trim(),
        status: status,
        priority: priority,
        assigneeId: assigneeId,
        dueDate: dueDate,
        createdAt: DateTime.now(),
      );
      _tasks.add(task);
      if (assigneeId != null) _notifyAssignment(task, assigneeId);
      return task;
    });
  }

  Future<Task> updateTask(Task task) {
    return _simulate(isWrite: true, () {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index == -1) {
        throw const NotFoundException('That task no longer exists.');
      }
      final previous = _tasks[index];
      _tasks[index] = task;

      final assignee = task.assigneeId;
      if (assignee != null && assignee != previous.assigneeId) {
        _notifyAssignment(task, assignee);
      }
      return task;
    });
  }

  Future<void> deleteTask(String id) {
    return _simulate(isWrite: true, () {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index == -1) {
        throw const NotFoundException('That task no longer exists.');
      }
      _tasks.removeAt(index);
      _comments.removeWhere((c) => c.taskId == id);
      _notifications.removeWhere((n) => n.taskId == id);
    });
  }

  void _notifyAssignment(Task task, String assigneeId) {
    _notifications.add(
      AppNotification(
        id: _nextId('notif'),
        userId: assigneeId,
        type: NotificationType.taskAssigned,
        message: 'You were assigned to "${task.title}"',
        read: false,
        createdAt: DateTime.now(),
        taskId: task.id,
      ),
    );
  }

  // --- Comments ---------------------------------------------------------

  Future<List<Comment>> commentsOf(String taskId) {
    return _simulate(() {
      return _comments.where((c) => c.taskId == taskId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

  Future<Comment> addComment({
    required String taskId,
    required String authorId,
    required String body,
  }) {
    return _simulate(isWrite: true, () {
      if (!_tasks.any((t) => t.id == taskId)) {
        throw const NotFoundException('That task no longer exists.');
      }
      final comment = Comment(
        id: _nextId('cmt'),
        taskId: taskId,
        authorId: authorId,
        body: body.trim(),
        createdAt: DateTime.now(),
      );
      _comments.add(comment);
      return comment;
    });
  }

  // --- Notifications ----------------------------------------------------

  Future<List<AppNotification>> notificationsOf(String userId) {
    return _simulate(() {
      return _notifications.where((n) => n.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> markNotificationRead(String id) {
    return _simulate(isWrite: true, () {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index == -1) return;
      _notifications[index] = _notifications[index].copyWith(read: true);
    });
  }

  Future<void> markAllNotificationsRead(String userId) {
    return _simulate(isWrite: true, () {
      for (var i = 0; i < _notifications.length; i++) {
        if (_notifications[i].userId == userId) {
          _notifications[i] = _notifications[i].copyWith(read: true);
        }
      }
    });
  }

  // --- Lookups ----------------------------------------------------------

  Future<List<User>> allUsers() => _simulate(() => List.unmodifiable(_users));

  /// Synchronous membership check used by the repository's authorization
  /// guard, which must run before any latency is applied.
  Future<bool> isMemberOfOrg(String userId, String orgId) async {
    await _ensureLoaded();
    return _memberships.any((m) => m.userId == userId && m.orgId == orgId);
  }

  Future<Organization?> organizationById(String id) async {
    await _ensureLoaded();
    return _organizations.where((o) => o.id == id).firstOrNull;
  }
}
