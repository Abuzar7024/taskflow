import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/app.dart';
import 'package:taskflow/core/storage/secure_store.dart';
import 'package:taskflow/domain/entities/enums.dart';
import 'package:taskflow/presentation/auth/auth_controller.dart';
import 'package:taskflow/presentation/providers.dart';
import 'package:taskflow/presentation/tasks/task_card.dart';

import 'package:taskflow/presentation/widgets/app_bottom_nav.dart';

import '../support/harness.dart';

/// End-to-end flows driven through the real router and screens, against the
/// mock data source. No network is involved.
///
/// These use `pump` with explicit durations rather than `pumpAndSettle`: the
/// skeleton loaders animate continuously, so the frame loop never settles.
Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Taps a bottom-navigation destination by index.
Future<void> tapNav(WidgetTester tester, int index) async {
  final bar = find.byType(AppBottomNav);
  expect(bar, findsOneWidget, reason: 'the shell should show the nav bar');
  await tester.tap(
    find.descendant(of: bar, matching: find.byType(InkWell)).at(index),
  );
  await settle(tester);
}

/// Scrolls a task into view and opens it. Low-priority tasks sort to the
/// bottom of the list, below the fold on a phone-sized surface.
Future<void> openTask(WidgetTester tester, String title) async {
  await scrollTo(tester, find.text(title));
  await tester.tap(find.text(title).first);
  await settle(tester);
}

/// Drags the primary scrollable until [finder] is on screen. A no-op when the
/// target is already visible.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 12 && finder.evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settle(tester);
}

/// Bottom-navigation indices, matching AppShell's destination order.
const navHome = 0;
const navProjects = 1;
const navTasks = 2;
const navInbox = 3;
const navProfile = 4;

Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  // Pin a phone-sized surface: the default 800x600 test window is wide
  // enough to trigger the tablet navigation rail.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = testContainer();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TaskFlowApp(),
    ),
  );
  await settle(tester);
  return container;
}

Future<void> signInThroughUi(
  WidgetTester tester, {
  String email = adminEmail,
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    testPassword,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await settle(tester);
}

void main() {
  setUpAll(preloadMockJson);

  group('login flow', () {
    testWidgets('splash lands on login when no session is stored', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('signing in reaches the dashboard', (tester) async {
      final container = await pumpApp(tester);
      await signInThroughUi(tester);

      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      expect(find.text('Nimbus Digital'), findsWidgets);
      expect(find.text('Projects'), findsWidgets);
    });

    testWidgets('the dashboard summarises projects and tasks', (tester) async {
      await pumpApp(tester);
      await signInThroughUi(tester);

      expect(find.text('Organization Admin'), findsWidgets);
      expect(find.text('Open tasks'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('a member sees their own role', (tester) async {
      await pumpApp(tester);
      await signInThroughUi(tester, email: memberEmail);

      expect(find.text('Member'), findsWidgets);
    });
  });

  group('project listing', () {
    testWidgets('lists the organization projects', (tester) async {
      await pumpApp(tester);
      await signInThroughUi(tester);

      await tapNav(tester, navProjects);

      expect(find.text('Website Relaunch'), findsWidgets);
      expect(find.text('Mobile App v2'), findsWidgets);
      // Belongs to the other organization.
      expect(find.text('Client Onboarding Revamp'), findsNothing);
    });

    testWidgets('opening a project shows its tasks and progress', (
      tester,
    ) async {
      await pumpApp(tester);
      await signInThroughUi(tester);

      await tapNav(tester, navProjects);
      await tester.tap(find.text('Website Relaunch').first);
      await settle(tester);

      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Fix broken contact form'), findsWidgets);
    });
  });

  group('task listing', () {
    testWidgets('lists tasks and opens a task detail', (tester) async {
      await pumpApp(tester);
      await signInThroughUi(tester);

      await tapNav(tester, navTasks);

      expect(find.byType(TaskCard), findsWidgets);

      await openTask(tester, 'Fix broken contact form');

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Assignee'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
      // Seeded comment on this task.
      expect(
        find.textContaining('Reproduced on Safari 17'),
        findsOneWidget,
      );
    });
  });

  group('create and update a task', () {
    testWidgets('creating a task adds it to the list', (tester) async {
      final container = await pumpApp(tester);
      await signInThroughUi(tester);
      final session = container.read(authControllerProvider).session!;

      final before = await container
          .read(taskRepositoryProvider)
          .list(session);

      await tapNav(tester, navTasks);
      await tester.tap(find.text('New task'));
      await settle(tester);

      expect(find.text('Create task'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Integration test task',
      );

      // Creating from the global list requires picking a project.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await settle(tester);
      await tester.tap(find.text('Website Relaunch').last);
      await settle(tester);

      await tester.tap(find.text('Create task'));
      await settle(tester);

      final after = await container.read(taskRepositoryProvider).list(session);
      expect(after.length, before.length + 1);
      expect(
        after.map((t) => t.title),
        contains('Integration test task'),
      );
    });

    testWidgets('an invalid task form blocks submission', (tester) async {
      final container = await pumpApp(tester);
      await signInThroughUi(tester);
      final session = container.read(authControllerProvider).session!;
      final before = await container
          .read(taskRepositoryProvider)
          .list(session);

      await tapNav(tester, navTasks);
      await tester.tap(find.text('New task'));
      await settle(tester);

      // Submit with an empty title.
      await tester.tap(find.text('Create task'));
      await settle(tester);

      expect(find.text('Give the task a title'), findsOneWidget);

      final after = await container.read(taskRepositoryProvider).list(session);
      expect(after.length, before.length);
    });

    testWidgets('changing status from the detail screen persists', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      await signInThroughUi(tester);
      final session = container.read(authControllerProvider).session!;

      await tapNav(tester, navTasks);
      await openTask(tester, 'SEO audit');

      await tester.tap(find.text('To Do').last);
      await settle(tester);

      expect(find.text('Move task to'), findsOneWidget);
      await tester.tap(find.text('In Review').last);
      await settle(tester);

      final task = await container
          .read(taskRepositoryProvider)
          .byId(session, Seed.seoTaskId);
      expect(task.status, TaskStatus.review);
    });
  });

  group('task assignment', () {
    testWidgets('assigning a teammate persists and notifies them', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      await signInThroughUi(tester);
      final session = container.read(authControllerProvider).session!;

      await tapNav(tester, navTasks);
      await openTask(tester, 'SEO audit');

      expect(find.text('Unassigned'), findsWidgets);

      await tester.tap(find.text('Unassigned').last);
      await settle(tester);

      expect(find.text('Assign task'), findsOneWidget);
      await tester.tap(find.text('Priya Nair').last);
      await settle(tester);

      final task = await container
          .read(taskRepositoryProvider)
          .byId(session, Seed.seoTaskId);
      expect(task.assigneeId, Seed.priyaId);

      final notifications = await container
          .read(notificationRepositoryProvider)
          .list(sessionFor(userId: Seed.priyaId));
      expect(notifications.any((n) => n.taskId == Seed.seoTaskId), isTrue);
    });

    testWidgets('the assignee list only offers org members', (tester) async {
      await pumpApp(tester);
      await signInThroughUi(tester);

      await tapNav(tester, navTasks);
      await openTask(tester, 'SEO audit');
      await tester.tap(find.text('Unassigned').last);
      await settle(tester);

      expect(find.text('Ava Thompson'), findsWidgets);
      expect(find.text('Priya Nair'), findsWidgets);
      // Members of Harborlight Studios must never appear.
      expect(find.text('Elena Vargas'), findsNothing);
      expect(find.text('Daniel Osei'), findsNothing);
    });
  });

  group('session and logout', () {
    testWidgets('logging out returns to login and blocks the app', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      await signInThroughUi(tester);

      await tapNav(tester, navProfile);

      await scrollTo(tester, find.text('Sign out'));
      await tester.tap(find.text('Sign out').first);
      await settle(tester);

      // Confirm the dialog.
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await settle(tester);

      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('a stored session restores straight to the dashboard', (
      tester,
    ) async {
      // Sign in once to populate the shared secure store.
      final store = InMemorySecureStore();
      final first = testContainer(secureStore: store);
      await signIn(first);

      final second = testContainer(secureStore: store);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: second,
          child: const TaskFlowApp(),
        ),
      );
      await settle(tester, 10);

      expect(second.read(authControllerProvider).isAuthenticated, isTrue);
      expect(find.text('Welcome back'), findsNothing);
    });
  });
}
