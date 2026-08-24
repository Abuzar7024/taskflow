import 'package:flutter/material.dart';

import '../../domain/entities/enums.dart';
import 'app_tokens.dart';

/// Semantic colours for task state. Hues are shared across themes so a status
/// reads the same in light and dark.
extension TaskStatusColors on TaskStatus {
  Color get color => switch (this) {
    TaskStatus.todo => AppPalette.slate,
    TaskStatus.inProgress => AppPalette.electric,
    TaskStatus.review => AppPalette.amber,
    TaskStatus.done => AppPalette.emerald,
  };

  IconData get icon => switch (this) {
    TaskStatus.todo => Icons.circle_outlined,
    TaskStatus.inProgress => Icons.play_circle_outline_rounded,
    TaskStatus.review => Icons.visibility_outlined,
    TaskStatus.done => Icons.check_circle_rounded,
  };
}

extension TaskPriorityColors on TaskPriority {
  Color get color => switch (this) {
    TaskPriority.low => AppPalette.slate,
    TaskPriority.medium => AppPalette.cyan,
    TaskPriority.high => AppPalette.amber,
    TaskPriority.urgent => AppPalette.coral,
  };

  IconData get icon => switch (this) {
    TaskPriority.low => Icons.south_rounded,
    TaskPriority.medium => Icons.remove_rounded,
    TaskPriority.high => Icons.north_rounded,
    TaskPriority.urgent => Icons.bolt_rounded,
  };
}

extension ProjectStatusColors on ProjectStatus {
  Color get color => switch (this) {
    ProjectStatus.active => AppPalette.emerald,
    ProjectStatus.archived => AppPalette.slate,
  };
}
