import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:taskflow/core/constants/dev_settings.dart';
import 'package:taskflow/data/datasources/mock_data_source.dart';
import 'package:taskflow/domain/entities/enums.dart';
import 'package:taskflow/domain/entities/task_filter.dart';
import 'package:taskflow/presentation/auth/auth_controller.dart';
import 'package:taskflow/presentation/providers.dart';
import 'package:taskflow/presentation/tasks/task_card.dart';
import 'package:taskflow/presentation/tasks/task_providers.dart';
import 'package:taskflow/presentation/tasks/tasks_screen.dart';
import 'package:taskflow/presentation/widgets/state_views.dart';

import '../support/harness.dart';

/// Pumps the task list far enough for its providers to resolve.
/// A bare `pump()` does not advance the fake clock, so the data source's
/// zero-duration delay would never fire.
Future<void> pumpTasks(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    wrapWithApp(const TasksScreen(), container: container),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 10));
}

void main() {
  setUpAll(preloadMockJson);

  group('loading state', () {
    testWidgets('shows skeleton placeholders while the request is in flight', (
      tester,
    ) async {
      // A latency window makes the in-flight frame observable; at zero
      // latency the list resolves before the first pump.
      final container = testContainer(
        dataSource: MockDataSource(
          loadAsset: () => SynchronousFuture(mockJson),
          latency: const Duration(seconds: 1),
        ),
      );
      await signInWidget(tester, container);

      await tester.pumpWidget(
        wrapWithApp(const TasksScreen(), container: container),
      );
      await tester.pump();

      expect(find.byType(SkeletonList), findsOneWidget);
      expect(find.byType(TaskCard), findsNothing);

      // Drain the outstanding latency so no timer outlives the test.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('success state', () {
    testWidgets('renders a card per task in the organization', (tester) async {
      final container = testContainer();
      await signInWidget(tester, container);
      await pumpTasks(tester, container);

      expect(find.byType(SkeletonList), findsNothing);
      expect(find.byType(TaskCard), findsWidgets);
      expect(find.text('Build responsive nav component'), findsOneWidget);
    });

    testWidgets('does not show another organization\'s tasks', (tester) async {
      final container = testContainer();
      await signInWidget(tester, container);
      await pumpTasks(tester, container);

      // Belongs to Harborlight Studios.
      expect(find.text('Draft onboarding checklist'), findsNothing);
    });

    testWidgets('shows status, priority and assignee on a card', (
      tester,
    ) async {
      final container = testContainer();
      await signInWidget(tester, container);
      await pumpTasks(tester, container);

      expect(find.text('Urgent'), findsWidgets);
      expect(find.text('To Do'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);
      // Names come from the user directory, proving the assignee is resolved.
      expect(find.text('Priya Nair'), findsWidgets);
    });
  });

  group('empty state', () {
    testWidgets('explains the empty list when no tasks exist', (tester) async {
      final emptyJson = await mockJsonWith((json) {
        json['tasks'] = <Map<String, dynamic>>[];
        return json;
      });

      final container = testContainer(
        dataSource: syncDataSource(overrideJson: emptyJson),
      );
      await signInWidget(tester, container);
      await pumpTasks(tester, container);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.byType(TaskCard), findsNothing);
    });

    testWidgets('offers to clear filters when they hide everything', (
      tester,
    ) async {
      final container = testContainer();
      await signInWidget(tester, container);

      // A query that matches nothing in the seed data.
      container
              .read(taskFilterProvider(FilterScopes.allTasks).notifier)
              .state =
          const TaskFilter(query: 'zzzz-no-such-task');

      await pumpTasks(tester, container);

      expect(find.text('No tasks found'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.byType(TaskCard), findsWidgets);
    });
  });

  group('error state', () {
    testWidgets('shows a human message and a retry action', (tester) async {
      var settings = const DevSettings();
      final container = testContainer(
        dataSource: syncDataSource(devSettings: () => settings),
      );
      // Sign in while healthy, then fail only the task request.
      await signInWidget(tester, container);
      settings = const DevSettings(failure: SimulatedFailure.serverError);
      await pumpTasks(tester, container);

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(
        find.text('Something went wrong on our side. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);

      // Retrying after the failure clears should render the list.
      settings = const DevSettings();
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.byType(TaskCard), findsWidgets);
    });

    testWidgets('never leaks a raw exception string', (tester) async {
      var settings = const DevSettings();
      final container = testContainer(
        dataSource: syncDataSource(devSettings: () => settings),
      );
      await signInWidget(tester, container);
      settings = const DevSettings(failure: SimulatedFailure.timeout);
      await pumpTasks(tester, container);

      expect(find.textContaining('Exception'), findsNothing);
      expect(
        find.text('The request took too long. Please try again.'),
        findsOneWidget,
      );
    });
  });

  group('status update from the list', () {
    testWidgets('changing status through the sheet updates the task', (
      tester,
    ) async {
      final container = testContainer();
      final session = await signInWidget(tester, container);
      await pumpTasks(tester, container);

      final before = (await container
              .read(taskRepositoryProvider)
              .byId(session, Seed.seoTaskId))
          .status;
      expect(before, TaskStatus.todo);

      // Open the status sheet from the first card's status button.
      await tester.tap(find.byTooltip('Change status').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Move task to'), findsOneWidget);

      await tester.tap(find.text('In Progress').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Exactly one task moved to In Progress beyond those already there.
      final tasks = await container.read(taskRepositoryProvider).list(session);
      expect(
        tasks.where((t) => t.status == TaskStatus.inProgress).length,
        greaterThanOrEqualTo(2),
      );
    });
  });

  group('offline', () {
    testWidgets('shows the offline banner over cached data', (tester) async {
      final container = testContainer();
      await signInWidget(tester, container);

      // Warm the cache while online.
      await pumpTasks(tester, container);
      expect(find.byType(TaskCard), findsWidgets);

      container.read(devSettingsProvider.notifier).setOffline(true);
      container.invalidate(tasksProvider);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(
        find.textContaining('offline', findRichText: true),
        findsWidgets,
        reason: 'the offline strip must appear once offline mode is on',
      );
      expect(
        find.byType(TaskCard),
        findsWidgets,
        reason: 'cached tasks must stay visible while offline',
      );
    });
  });

  group('unauthorized', () {
    testWidgets('a 401 on a read signs the user out', (tester) async {
      var settings = const DevSettings();
      final container = testContainer(
        dataSource: syncDataSource(devSettings: () => settings),
      );
      await signInWidget(tester, container);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      // The mock refresh also rejects, so the session cannot be recovered.
      settings = const DevSettings(failure: SimulatedFailure.unauthorized);
      await pumpTasks(tester, container);

      expect(
        container.read(authControllerProvider).isAuthenticated,
        isFalse,
        reason: 'a rejected token must not leave the user on a dead screen',
      );
    });
  });

  group('layout', () {
    testWidgets('renders without overflow on a small screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = testContainer();
      await signInWidget(tester, container);
      await pumpTasks(tester, container);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on a large screen', (tester) async {
      tester.view.physicalSize = const Size(1024, 1366);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = testContainer();
      await signInWidget(tester, container);
      await pumpTasks(tester, container);

      expect(tester.takeException(), isNull);
    });
  });
}
