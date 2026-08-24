import 'package:flutter/material.dart';

import '../../domain/entities/enums.dart';
import 'app_theme.dart';

extension TaskStatusColors on TaskStatus {
  Color get color => switch (this) {
    TaskStatus.todo => AppColors.todo,
    TaskStatus.inProgress => AppColors.inProgress,
    TaskStatus.review => AppColors.review,
    TaskStatus.done => AppColors.done,
  };

  IconData get icon => switch (this) {
    TaskStatus.todo => Icons.radio_button_unchecked,
    TaskStatus.inProgress => Icons.timelapse,
    TaskStatus.review => Icons.rate_review_outlined,
    TaskStatus.done => Icons.check_circle,
  };
}

extension TaskPriorityColors on TaskPriority {
  Color get color => switch (this) {
    TaskPriority.low => AppColors.priorityLow,
    TaskPriority.medium => AppColors.priorityMedium,
    TaskPriority.high => AppColors.priorityHigh,
    TaskPriority.urgent => AppColors.priorityUrgent,
  };

  IconData get icon => switch (this) {
    TaskPriority.low => Icons.keyboard_arrow_down,
    TaskPriority.medium => Icons.drag_handle,
    TaskPriority.high => Icons.keyboard_arrow_up,
    TaskPriority.urgent => Icons.priority_high,
  };
}

/// Tints a semantic accent so it reads correctly as a chip background in both
/// light and dark themes.
Color tintFor(Color accent, Brightness brightness) {
  return accent.withValues(alpha: brightness == Brightness.dark ? 0.22 : 0.12);
}
