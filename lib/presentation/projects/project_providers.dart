import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import '../auth/auth_controller.dart';
import '../providers.dart';

/// Projects for the signed-in organization.
///
/// Refreshing the token before the call keeps an expired access token from
/// surfacing as a spurious failure in the UI.
final projectsProvider = FutureProvider.autoDispose<List<Project>>((ref) {
  final session = ref.watch(sessionProvider);
  final repository = ref.watch(projectRepositoryProvider);
  return authenticatedRead(ref, () => repository.list(session));
});

final projectByIdProvider = FutureProvider.autoDispose
    .family<Project, String>((ref, projectId) {
      final session = ref.watch(sessionProvider);
      final repository = ref.watch(projectRepositoryProvider);
      return authenticatedRead(ref, () => repository.byId(session, projectId));
    });

/// When the currently displayed project list was last written to cache, used
/// to label stale data while offline.
final projectsCachedAtProvider = Provider.autoDispose<DateTime?>((ref) {
  final session = ref.watch(authControllerProvider).session;
  if (session == null) return null;
  return ref.watch(projectRepositoryProvider).cachedAt(session.orgId);
});

/// How the project list is ordered.
enum ProjectSort {
  recent('Recently created'),
  nameAsc('Name'),
  mostTasks('Most tasks');

  const ProjectSort(this.label);

  final String label;
}

/// Free-text query applied to the project list.
final projectQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final projectSortProvider = StateProvider.autoDispose<ProjectSort>(
  (ref) => ProjectSort.recent,
);

/// Pure search + sort, kept out of the widget so it can be unit tested.
List<Project> searchAndSortProjects(
  List<Project> projects,
  String query,
  ProjectSort sort,
) {
  final normalized = query.trim().toLowerCase();
  final filtered = normalized.isEmpty
      ? [...projects]
      : projects
            .where(
              (p) =>
                  p.name.toLowerCase().contains(normalized) ||
                  p.description.toLowerCase().contains(normalized),
            )
            .toList();

  filtered.sort(switch (sort) {
    ProjectSort.recent => (a, b) => b.createdAt.compareTo(a.createdAt),
    ProjectSort.nameAsc => (a, b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    ProjectSort.mostTasks => (a, b) => b.taskCount.compareTo(a.taskCount),
  });
  return filtered;
}
