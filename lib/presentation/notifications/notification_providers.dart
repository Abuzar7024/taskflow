import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/session.dart';
import '../auth/auth_controller.dart';
import '../providers.dart';

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) {
    final session = ref.watch(sessionProvider);
    final repository = ref.watch(notificationRepositoryProvider);
    return authenticatedRead(ref, () => repository.list(session));
  },
);

/// Unread count for the app-bar badge. Falls back to zero while loading or on
/// failure — a badge is not worth surfacing an error for.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref
      .watch(notificationsProvider)
      .maybeWhen(
        data: (items) => items.where((n) => !n.read).length,
        orElse: () => 0,
      );
});

class NotificationController extends StateNotifier<bool> {
  NotificationController(this._ref) : super(false);

  final Ref _ref;

  Future<void> markRead(String id) => _run(
    (session) =>
        _ref.read(notificationRepositoryProvider).markRead(session, id),
  );

  Future<void> markAllRead() => _run(
    (session) => _ref.read(notificationRepositoryProvider).markAllRead(session),
  );

  Future<void> _run(Future<void> Function(Session session) action) async {
    if (state) return;
    state = true;
    try {
      await action(_ref.read(sessionProvider));
      _ref.invalidate(notificationsProvider);
    } on AppException {
      // Marking a notification read is incidental; failing silently is better
      // than interrupting the user with an error they cannot act on.
    } finally {
      state = false;
    }
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, bool>((ref) {
      return NotificationController(ref);
    });
