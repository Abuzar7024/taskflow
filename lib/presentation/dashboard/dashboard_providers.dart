import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import '../auth/auth_controller.dart';
import '../projects/project_providers.dart';
import '../providers.dart';
import '../tasks/task_providers.dart';

class DashboardData extends Equatable {
  const DashboardData({
    required this.projects,
    required this.stats,
    required this.myOpenTasks,
    required this.upcoming,
  });

  final List<Project> projects;
  final TaskStats stats;

  /// Open tasks assigned to the signed-in user, most urgent first.
  final List<Task> myOpenTasks;

  /// Open tasks across the org with the nearest due dates.
  final List<Task> upcoming;

  int get projectCount => projects.length;

  @override
  List<Object?> get props => [projects, stats, myOpenTasks, upcoming];
}

/// Combines projects and tasks into the dashboard summary.
///
/// Both sources are already cached by their repositories, so this stays a
/// derived view rather than an extra round trip.
final dashboardProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final session = ref.watch(sessionProvider);
  final now = ref.watch(clockProvider)();

  final projects = await ref.watch(projectsProvider.future);
  final tasks = await ref.watch(tasksProvider.future);

  final mine =
      tasks
          .where((t) => t.assigneeId == session.userId && !t.status.isComplete)
          .toList()
        ..sort((a, b) {
          final byPriority = b.priority.weight.compareTo(a.priority.weight);
          if (byPriority != 0) return byPriority;
          return _nullsLast(a.dueDate, b.dueDate);
        });

  final upcoming =
      tasks
          .where((t) => !t.status.isComplete && t.dueDate != null)
          .toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  return DashboardData(
    projects: projects,
    stats: TaskStats.from(tasks, now),
    myOpenTasks: mine.take(5).toList(),
    upcoming: upcoming.take(5).toList(),
  );
});

int _nullsLast(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
