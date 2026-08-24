import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';

/// Mapping between the mock backend's wire format and the domain entities.
///
/// Kept as extension-style mappers rather than parallel model classes: the
/// wire shape and the domain shape are close enough that a second set of
/// classes would be pure ceremony.

extension OrganizationMapper on Organization {
  static Organization fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
  };
}

extension UserMapper on User {
  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar_url': avatarUrl,
  };
}

extension ProjectMapper on Project {
  /// [taskCount] is supplied by the data source from the live task rows; the
  /// `task_count` field in the seed file is only a fallback for cached reads.
  static Project fromJson(Map<String, dynamic> json, {int? taskCount}) {
    return Project(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: ProjectStatus.fromWire(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      taskCount: taskCount ?? (json['task_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'org_id': orgId,
    'name': name,
    'description': description,
    'status': status.wireValue,
    'created_at': createdAt.toIso8601String(),
    'task_count': taskCount,
  };
}

extension TaskMapper on Task {
  static Task fromJson(Map<String, dynamic> json) {
    final dueDate = json['due_date'] as String?;
    return Task(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: TaskStatus.fromWire(json['status'] as String),
      priority: TaskPriority.fromWire(json['priority'] as String),
      assigneeId: json['assignee_id'] as String?,
      dueDate: dueDate == null ? null : DateTime.parse(dueDate),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'title': title,
    'description': description,
    'status': status.wireValue,
    'priority': priority.wireValue,
    'assignee_id': assigneeId,
    'due_date': dueDate == null ? null : _wireDate(dueDate!),
    'created_at': createdAt.toIso8601String(),
  };

  static String _wireDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

extension CommentMapper on Comment {
  static Comment fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      authorId: json['author_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'task_id': taskId,
    'author_id': authorId,
    'body': body,
    'created_at': createdAt.toIso8601String(),
  };
}

extension NotificationMapper on AppNotification {
  static AppNotification fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromWire(json['type'] as String),
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      taskId: json['task_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type.wireValue,
    'message': message,
    'read': read,
    'created_at': createdAt.toIso8601String(),
    'task_id': taskId,
  };
}

/// A credential row from `auth_mock.test_credentials`.
class MockCredential {
  const MockCredential({
    required this.email,
    required this.password,
    required this.orgId,
    required this.role,
  });

  factory MockCredential.fromJson(Map<String, dynamic> json) {
    return MockCredential(
      email: json['email'] as String,
      password: json['password'] as String,
      orgId: json['org_id'] as String,
      role: OrgRole.fromWire(json['role'] as String),
    );
  }

  final String email;
  final String password;
  final String orgId;
  final OrgRole role;
}

/// The token lifetimes returned by `auth_mock.mock_login_response`.
class MockLoginResponse {
  const MockLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenLifetimeSeconds,
    required this.refreshTokenLifetimeSeconds,
  });

  factory MockLoginResponse.fromJson(Map<String, dynamic> json) {
    return MockLoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessTokenLifetimeSeconds:
          (json['access_token_expires_in_seconds'] as num).toInt(),
      refreshTokenLifetimeSeconds:
          (json['refresh_token_expires_in_seconds'] as num).toInt(),
    );
  }

  final String accessToken;
  final String refreshToken;
  final int accessTokenLifetimeSeconds;
  final int refreshTokenLifetimeSeconds;
}
