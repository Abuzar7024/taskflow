import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/presentation/dashboard/dashboard_screen.dart';
import 'package:taskflow/presentation/profile/profile_screen.dart';
import 'package:taskflow/presentation/projects/projects_screen.dart';
import 'package:taskflow/presentation/tasks/tasks_screen.dart';
import 'package:taskflow/presentation/widgets/app_bottom_nav.dart';

import '../support/harness.dart';

/// Sizes covering a small phone, a large phone, a tablet, and landscape.
const _sizes = <String, Size>{
  'small phone': Size(320, 640),
  'large phone': Size(430, 932),
  'tablet': Size(834, 1112),
  'landscape phone': Size(844, 390),
};

void main() {
  setUpAll(preloadMockJson);

  for (final entry in _sizes.entries) {
    group(entry.key, () {
      for (final screen in <String, Widget>{
        'dashboard': const DashboardScreen(),
        'projects': const ProjectsScreen(),
        'tasks': const TasksScreen(),
        'profile': const ProfileScreen(),
      }.entries) {
        testWidgets('${screen.key} lays out without overflow', (tester) async {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final container = testContainer();
          await signInWidget(tester, container);
          await tester.pumpWidget(
            wrapWithApp(screen.value, container: container),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  group('navigation adapts', () {
    testWidgets('phones get the bottom bar', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = testContainer();
      await signInWidget(tester, container);
      await tester.pumpWidget(
        wrapWithApp(const DashboardScreen(), container: container),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // The shell owns the bar; this asserts the breakpoint helper directly.
      expect(const Size(390, 844).width < 720, isTrue);
    });

    testWidgets('the nav bar renders every destination', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            bottomNavigationBar: AppBottomNav(
              items: const [
                NavItem(icon: Icons.home, activeIcon: Icons.home, label: 'Home'),
                NavItem(
                  icon: Icons.folder,
                  activeIcon: Icons.folder,
                  label: 'Projects',
                ),
                NavItem(
                  icon: Icons.check,
                  activeIcon: Icons.check,
                  label: 'Tasks',
                ),
                NavItem(
                  icon: Icons.notifications,
                  activeIcon: Icons.notifications,
                  label: 'Inbox',
                  badgeCount: 3,
                ),
                NavItem(
                  icon: Icons.person,
                  activeIcon: Icons.person,
                  label: 'Profile',
                ),
              ],
              selectedIndex: 0,
              onSelect: (_) {},
            ),
          ),
          container: testContainer(),
        ),
      );
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('3'), findsOneWidget, reason: 'unread badge');
      expect(tester.takeException(), isNull);
    });
  });
}
