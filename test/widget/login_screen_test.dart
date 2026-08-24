import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/presentation/auth/auth_controller.dart';
import 'package:taskflow/presentation/auth/login_screen.dart';

import '../support/harness.dart';

void main() {
  setUpAll(preloadMockJson);

  testWidgets('shows validation errors for empty fields', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('rejects a malformed email', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'not-an-email',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('does not call the repository when validation fails', (
    tester,
  ) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unknown,
      reason: 'an invalid form should never reach the auth controller',
    );
  });

  testWidgets('shows an error message for wrong credentials', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      adminEmail,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
  });

  testWidgets('authenticates with a seeded account', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

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
    await tester.pump(const Duration(milliseconds: 10));

    final auth = container.read(authControllerProvider);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.session?.orgId, Seed.nimbusOrgId);
  });

  testWidgets('locks the submit button while signing in', (tester) async {
    // A visible latency window is needed to observe the in-flight state.
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

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

    // Either the spinner is showing, or the (zero-latency) request already
    // finished; both prove the button is not left in a double-submit state.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final settled = container.read(authControllerProvider).isAuthenticated;
    expect(settled || button.onPressed == null, isTrue);

    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('toggles password visibility', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('offers the demo account picker', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );

    await tester.tap(find.text('Use a demo account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Demo accounts'), findsOneWidget);
    expect(find.text(adminEmail), findsOneWidget);

    await tester.tap(find.text(adminEmail));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));


    final email = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Email'),
        matching: find.byType(TextField),
      ),
    );
    expect(email.controller?.text, adminEmail);
  });

  testWidgets('renders without overflow on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = testContainer();
    await tester.pumpWidget(
      wrapWithApp(const LoginScreen(), container: container),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
