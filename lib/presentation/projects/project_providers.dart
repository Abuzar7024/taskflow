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
