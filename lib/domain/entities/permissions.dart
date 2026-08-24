import '../../core/errors/app_exception.dart';
import 'session.dart';

/// The authorization rules, in one place.
///
/// Repositories call the `require*` guards before every protected operation,
/// so an unauthorized call fails even when the UI never showed the button.
/// The boolean `can*` getters exist so the UI can additionally hide actions.
///
/// Creating and editing projects and tasks is open to every member of the
/// organization, so only the admin-restricted actions appear here.
abstract final class Permissions {
  static bool canDeleteProject(Session session) => session.isAdmin;

  static bool canManageMembers(Session session) => session.isAdmin;

  static void requireAdmin(Session session, String action) {
    if (!session.isAdmin) {
      throw ForbiddenException('Only organization admins can $action.');
    }
  }

  /// Guards tenant isolation: the record must belong to the session's org.
  static void requireSameOrg(Session session, String orgId) {
    if (session.orgId != orgId) {
      throw const ForbiddenException(
        'That item belongs to another organization.',
      );
    }
  }
}
