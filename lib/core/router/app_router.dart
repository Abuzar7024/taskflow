import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/auth_controller.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/auth/splash_screen.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/profile/developer_tools_screen.dart';
import '../../presentation/profile/settings_screens.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/projects/project_detail_screen.dart';
import '../../presentation/projects/project_form_screen.dart';
import '../../presentation/projects/projects_screen.dart';
import '../../presentation/shell/app_shell.dart';
import '../../presentation/tasks/task_detail_screen.dart';
import '../../presentation/tasks/task_form_screen.dart';
import '../../presentation/tasks/tasks_screen.dart';

/// Route paths and names in one place, so navigation calls never spell a
/// path by hand.
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const projects = '/projects';
  static const tasks = '/tasks';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const developerTools = '/profile/developer';
  static const accountSettings = '/profile/account';
  static const themeSettings = '/profile/theme';
  static const sessionSettings = '/profile/session';
  static const members = '/profile/members';

  static String project(String id) => '/projects/$id';
  static String newProject() => '/projects/new';
  static String editProject(String id) => '/projects/$id/edit';

  static String task(String id) => '/tasks/$id';
  static String editTask(String id) => '/tasks/$id/edit';

  /// Task creation is always scoped to a project.
  static String newTask({String? projectId}) =>
      projectId == null ? '/tasks/new' : '/tasks/new?projectId=$projectId';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // A plain Listenable bridge keeps GoRouter's refresh tied to auth changes
  // without rebuilding the router itself on every state emission.
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthRoute =
          location == Routes.login || location == Routes.register;

      // Developer tools stay reachable while signed out: the Unauthorized
      // simulation ends the session, and its own switch would otherwise be
      // stranded behind the login wall.
      if (location == Routes.developerTools) return null;

      // Hold on the splash screen until the stored session has been read.
      if (auth.status == AuthStatus.unknown) {
        return location == Routes.splash ? null : Routes.splash;
      }

      if (!auth.isAuthenticated) {
        return isAuthRoute ? null : Routes.login;
      }

      // Signed in: keep the user out of the splash and auth screens.
      if (isAuthRoute || location == Routes.splash) return Routes.dashboard;

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Task creation and editing sit outside the shell so they present as
      // full-screen forms without the bottom navigation bar.
      GoRoute(
        path: '/tasks/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TaskFormScreen(
          initialProjectId: state.uri.queryParameters['projectId'],
        ),
      ),
      GoRoute(
        path: '/tasks/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            TaskFormScreen(taskId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/projects/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProjectFormScreen(),
      ),
      GoRoute(
        path: '/projects/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ProjectFormScreen(projectId: state.pathParameters['id']),
      ),
      GoRoute(
        path: Routes.developerTools,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeveloperToolsScreen(),
      ),
      GoRoute(
        path: Routes.accountSettings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: Routes.themeSettings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: Routes.sessionSettings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SessionSettingsScreen(),
      ),
      GoRoute(
        path: Routes.members,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MembersScreen(),
      ),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: Routes.projects,
            builder: (context, state) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ProjectDetailScreen(projectId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: Routes.tasks,
            builder: (context, state) => const TasksScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    TaskDetailScreen(taskId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: Routes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteNotFoundScreen(
      location: state.matchedLocation,
    ),
  );
});

/// Notifies GoRouter when the authentication status changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.status != next.status) notifyListeners();
      },
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 40),
              const SizedBox(height: 16),
              Text(
                'We could not find $location.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(Routes.dashboard),
                child: const Text('Go to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
