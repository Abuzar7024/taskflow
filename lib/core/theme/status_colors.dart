import 'package:flutter/material.dart';

import '../../domain/entities/enums.dart';
import 'app_colors.dart';

/// Restrained status colour coding: blue for active work, green for done,
/// amber for attention, red for overdue or urgent.
extension TaskStatusColors on TaskStatus {
  Color color(ThemeData theme) => switch (this) {
    TaskStatus.todo => theme.c.textMuted,
    TaskStatus.inProgress => theme.c.primary,
    TaskStatus.review => theme.c.warning,
    TaskStatus.done => theme.c.success,
  };

  IconData get icon => switch (this) {
    TaskStatus.todo => Icons.circle_outlined,
    TaskStatus.inProgress => Icons.timelapse_rounded,
    TaskStatus.review => Icons.visibility_outlined,
    TaskStatus.done => Icons.check_circle_rounded,
  };
}

extension TaskPriorityColors on TaskPriority {
  Color color(ThemeData theme) => switch (this) {
    TaskPriority.low => theme.c.textMuted,
    TaskPriority.medium => theme.c.primary,
    TaskPriority.high => theme.c.warning,
    TaskPriority.urgent => theme.c.error,
  };

  IconData get icon => switch (this) {
    TaskPriority.low => Icons.south_rounded,
    TaskPriority.medium => Icons.remove_rounded,
    TaskPriority.high => Icons.north_rounded,
    TaskPriority.urgent => Icons.priority_high_rounded,
  };
}

extension ProjectStatusColors on ProjectStatus {
  Color color(ThemeData theme) => switch (this) {
    ProjectStatus.active => theme.c.success,
    ProjectStatus.archived => theme.c.textMuted,
  };
}
