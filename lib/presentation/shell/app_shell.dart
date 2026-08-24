import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// Bottom-navigation frame around the four primary sections.
///
/// On wide screens the bar is replaced by a side rail so a tablet does not
/// waste horizontal space.
class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const _destinations = [
    (route: Routes.dashboard, icon: Icons.space_dashboard_outlined,
     selectedIcon: Icons.space_dashboard, label: 'Home'),
    (route: Routes.projects, icon: Icons.folder_outlined,
     selectedIcon: Icons.folder, label: 'Projects'),
    (route: Routes.tasks, icon: Icons.check_circle_outline,
     selectedIcon: Icons.check_circle, label: 'Tasks'),
    (route: Routes.notifications, icon: Icons.notifications_none_rounded,
     selectedIcon: Icons.notifications_rounded, label: 'Inbox'),
    (route: Routes.profile, icon: Icons.person_outline,
     selectedIcon: Icons.person, label: 'Profile'),
  ];

  /// Highlights the section that owns the current location, so a nested route
  /// such as `/projects/proj_1001` keeps "Projects" selected.
  int get _selectedIndex {
    final index = _destinations.lastIndexWhere(
      (d) => location == d.route || location.startsWith('${d.route}/'),
    );
    return index < 0 ? 0 : index;
  }

  void _onSelect(BuildContext context, int index) {
    final destination = _destinations[index];
    // Re-tapping the active tab returns to that section's root.
    if (index == _selectedIndex && location != destination.route) {
      context.go(destination.route);
      return;
    }
    if (index != _selectedIndex) context.go(destination.route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useRail = MediaQuery.sizeOf(context).width >= 720;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => _onSelect(context, i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => _onSelect(context, i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
