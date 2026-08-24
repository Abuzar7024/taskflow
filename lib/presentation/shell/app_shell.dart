import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../notifications/notification_providers.dart';
import '../widgets/app_bottom_nav.dart';

/// Navigation frame around the five primary sections.
///
/// Phones get the bottom bar; tablets a collapsed rail; large tablets and
/// landscape an extended rail with labels — an adaptive layout rather than a
/// stretched phone one.
class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const _routes = [
    Routes.dashboard,
    Routes.projects,
    Routes.tasks,
    Routes.notifications,
    Routes.profile,
  ];

  /// Highlights the section that owns the current location, so a nested route
  /// such as `/projects/proj_1001` keeps "Projects" selected.
  int get _selectedIndex {
    final index = _routes.lastIndexWhere(
      (r) => location == r || location.startsWith('$r/'),
    );
    return index < 0 ? 0 : index;
  }

  void _onSelect(BuildContext context, int index) {
    final route = _routes[index];
    // Re-tapping the active tab returns to that section's root.
    if (index == _selectedIndex && location != route) {
      context.go(route);
      return;
    }
    if (index != _selectedIndex) context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final width = MediaQuery.sizeOf(context).width;

    final items = [
      const NavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'Home',
      ),
      const NavItem(
        icon: Icons.folder_outlined,
        activeIcon: Icons.folder_rounded,
        label: 'Projects',
      ),
      const NavItem(
        icon: Icons.check_circle_outline_rounded,
        activeIcon: Icons.check_circle_rounded,
        label: 'Tasks',
      ),
      NavItem(
        icon: Icons.notifications_none_rounded,
        activeIcon: Icons.notifications_rounded,
        label: 'Inbox',
        badgeCount: unread,
      ),
      const NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    if (width >= 720) {
      return Scaffold(
        body: Row(
          children: [
            AppNavRail(
              items: items,
              selectedIndex: _selectedIndex,
              onSelect: (i) => _onSelect(context, i),
              extended: width >= 1000,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        items: items,
        selectedIndex: _selectedIndex,
        onSelect: (i) => _onSelect(context, i),
      ),
    );
  }
}
