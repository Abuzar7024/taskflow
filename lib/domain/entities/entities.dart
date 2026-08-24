import 'package:equatable/equatable.dart';

import 'enums.dart';

class Organization extends Equatable {
  const Organization({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, createdAt];
}

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  List<Object?> get props => [id, name, email, avatarUrl];
}

/// A user together with their role in a specific organization.
class OrgMember extends Equatable {
  const OrgMember({
    required this.user,
    required this.orgId,
    required this.role,
  });

  final User user;
  final String orgId;
  final OrgRole role;

  @override
  List<Object?> get props => [user, orgId, role];
}

class Project extends Equatable {
  const Project({
    required this.id,
    required this.orgId,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.taskCount,
  });

  final String id;
  final String orgId;
  final String name;
  final String description;
  final ProjectStatus status;
  final DateTime createdAt;

  /// Derived from the current task rows rather than a stored counter, so it
  /// stays correct after tasks are added or removed.
  final int taskCount;

  Project copyWith({
    String? name,
    String? description,
    ProjectStatus? status,
    int? taskCount,
  }) {
    return Project(
      id: id,
      orgId: orgId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      taskCount: taskCount ?? this.taskCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orgId,
    name,
    description,
    status,
    createdAt,
    taskCount,
  ];
}

class Task extends Equatable {
  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.assigneeId,
    this.dueDate,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final DateTime? dueDate;
  final DateTime createdAt;

  bool get isAssigned => assigneeId != null;

  /// A task counts as overdue only while it is still open.
  bool isOverdue(DateTime now) {
    final due = dueDate;
    if (due == null || status.isComplete) return false;
    return due.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool isDueToday(DateTime now) {
    final due = dueDate;
    if (due == null || status.isComplete) return false;
    return due.year == now.year && due.month == now.month && due.day == now.day;
  }

  /// `clearAssignee` / `clearDueDate` exist because passing `null` to a
  /// nullable copyWith parameter is indistinguishable from omitting it.
  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeId,
    bool clearAssignee = false,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    title,
    description,
    status,
    priority,
    assigneeId,
    dueDate,
    createdAt,
  ];
}

class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, taskId, authorId, body, createdAt];
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.read,
    required this.createdAt,
    this.taskId,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String message;
  final bool read;
  final DateTime createdAt;
  final String? taskId;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      message: message,
      read: read ?? this.read,
      createdAt: createdAt,
      taskId: taskId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    message,
    read,
    createdAt,
    taskId,
  ];
}

/// Aggregated task counts used by the dashboard and project detail screens.
class TaskStats extends Equatable {
  const TaskStats({
    required this.total,
    required this.byStatus,
    required this.overdue,
  });

  factory TaskStats.from(List<Task> tasks, DateTime now) {
    final byStatus = <TaskStatus, int>{for (final s in TaskStatus.values) s: 0};
    var overdue = 0;
    for (final task in tasks) {
      byStatus[task.status] = byStatus[task.status]! + 1;
      if (task.isOverdue(now)) overdue++;
    }
    return TaskStats(
      total: tasks.length,
      byStatus: Map.unmodifiable(byStatus),
      overdue: overdue,
    );
  }

  final int total;
  final Map<TaskStatus, int> byStatus;
  final int overdue;

  int get completed => byStatus[TaskStatus.done] ?? 0;
  int get open => total - completed;

  double get completionRate => total == 0 ? 0 : completed / total;

  @override
  List<Object?> get props => [total, byStatus, overdue];
}
