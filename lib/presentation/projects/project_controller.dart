import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/entities.dart';
import '../auth/auth_controller.dart';
import '../mutation_result.dart';
import '../providers.dart';
import 'project_providers.dart';

/// Create/update/delete for projects. Exposes `isBusy` so forms can lock
/// their submit button while a request is in flight.
class ProjectController extends StateNotifier<bool> {
  ProjectController(this._ref) : super(false);

  final Ref _ref;

  Future<MutationResult<Project>> create({
    required String name,
    required String description,
  }) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref
          .read(projectRepositoryProvider)
          .create(session, name: name, description: description);
    });
  }

  Future<MutationResult<Project>> update(Project project) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref.read(projectRepositoryProvider).update(session, project);
    });
  }

  Future<MutationResult<void>> delete(String projectId) {
    return _run(() {
      final session = _ref.read(sessionProvider);
      return _ref.read(projectRepositoryProvider).delete(session, projectId);
    });
  }

  /// Wraps every mutation with the busy flag, token refresh, error mapping and
  /// cache invalidation, so each operation above stays a single expression.
  Future<MutationResult<T>> _run<T>(Future<T> Function() action) async {
    if (state) {
      return const MutationFailure('Please wait for the current change.');
    }
    state = true;
    try {
      final auth = _ref.read(authControllerProvider.notifier);
      await auth.ensureValidAccessToken();
      final value = await action();
      _invalidate();
      return MutationSuccess(value);
    } on ValidationException catch (e) {
      return MutationFailure(e.message, e.fieldErrors);
    } on UnauthorizedException catch (e) {
      await _ref.read(authControllerProvider.notifier).handleUnauthorized();
      return MutationFailure(e.message);
    } on AppException catch (e) {
      return MutationFailure(e.message);
    } finally {
      state = false;
    }
  }

  void _invalidate() {
    _ref.invalidate(projectsProvider);
  }
}

final projectControllerProvider =
    StateNotifierProvider<ProjectController, bool>((ref) {
      return ProjectController(ref);
    });
