library;

/// Enum values mirror the wire format used in the mock data so that parsing and
/// serialising stay symmetrical.

enum TaskStatus {
  todo('todo', 'To Do'),
  inProgress('in_progress', 'In Progress'),
  review('review', 'In Review'),
  done('done', 'Done');

  const TaskStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static TaskStatus fromWire(String value) {
    return TaskStatus.values.firstWhere(
      (s) => s.wireValue == value,
      orElse: () => throw FormatException('Unknown task status: $value'),
    );
  }

  bool get isComplete => this == TaskStatus.done;
}

enum TaskPriority {
  low('low', 'Low', 0),
  medium('medium', 'Medium', 1),
  high('high', 'High', 2),
  urgent('urgent', 'Urgent', 3);

  const TaskPriority(this.wireValue, this.label, this.weight);

  final String wireValue;
  final String label;

  /// Higher weight sorts first in task lists.
  final int weight;

  static TaskPriority fromWire(String value) {
    return TaskPriority.values.firstWhere(
      (p) => p.wireValue == value,
      orElse: () => throw FormatException('Unknown task priority: $value'),
    );
  }
}

enum ProjectStatus {
  active('active', 'Active'),
  archived('archived', 'Archived');

  const ProjectStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static ProjectStatus fromWire(String value) {
    return ProjectStatus.values.firstWhere(
      (s) => s.wireValue == value,
      orElse: () => throw FormatException('Unknown project status: $value'),
    );
  }
}

enum OrgRole {
  orgAdmin('org_admin', 'Organization Admin'),
  member('member', 'Member');

  const OrgRole(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static OrgRole fromWire(String value) {
    return OrgRole.values.firstWhere(
      (r) => r.wireValue == value,
      orElse: () => throw FormatException('Unknown role: $value'),
    );
  }

  bool get isAdmin => this == OrgRole.orgAdmin;
}

enum NotificationType {
  taskAssigned('task_assigned'),
  taskCommented('task_commented'),
  projectUpdated('project_updated');

  const NotificationType(this.wireValue);

  final String wireValue;

  /// Notification types are display-only; an unrecognised type degrades to a
  /// generic one rather than breaking the whole list.
  static NotificationType fromWire(String value) {
    return NotificationType.values.firstWhere(
      (t) => t.wireValue == value,
      orElse: () => NotificationType.projectUpdated,
    );
  }
}
