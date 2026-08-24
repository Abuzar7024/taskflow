import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/constants/dev_settings.dart';
import 'package:taskflow/presentation/auth/auth_controller.dart';
import 'package:taskflow/presentation/auth/login_screen.dart';
import 'package:taskflow/presentation/providers.dart';

import '../support/harness.dart';

/// The Unauthorized simulation signs the user out, so the switch that caused
/// it must stay reachable from the login screen.
void main() {
  setUpAll(preloadMockJson);

  testWidgets('offers developer options from the login screen', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

    expect(find.text('Developer options'), findsOneWidget);
  });

  testWidgets('hides the simulation notice when nothing is simulated', (
    tester,
  ) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

    expect(find.text('Simulation active'), findsNothing);
  });

  testWidgets('warns when a simulation is blocking sign-in', (tester) async {
    final container = testContainer();
    container
        .read(devSettingsProvider.notifier)
        .setFailure(SimulatedFailure.unauthorized);

    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );
    await tester.pump();

    expect(find.text('Simulation active'), findsOneWidget);
    expect(find.text('Reset simulation'), findsOneWidget);
    expect(find.textContaining('Unauthorized'), findsOneWidget);
  });

  testWidgets('resetting clears the simulation and the notice', (tester) async {
    final container = testContainer();
    container.read(devSettingsProvider.notifier).setOffline(true);

    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );
    await tester.pump();
    expect(find.text('Simulation active'), findsOneWidget);

    await tester.tap(find.text('Reset simulation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(container.read(devSettingsProvider).isDefault, isTrue);
    expect(find.text('Simulation active'), findsNothing);
  });

  testWidgets('after resetting, sign-in succeeds again', (tester) async {
    final container = testContainer();
    container
        .read(devSettingsProvider.notifier)
        .setFailure(SimulatedFailure.unauthorized);

    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );
    await tester.pump();

    await tester.tap(find.text('Reset simulation'));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      adminEmail,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      testPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(container.read(authControllerProvider).isAuthenticated, isTrue);
  });
}
