import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/constants/dev_settings.dart';
import 'package:taskflow/core/storage/local_store.dart';
import 'package:taskflow/core/storage/secure_store.dart';
import 'package:taskflow/core/theme/app_theme.dart';
import 'package:taskflow/data/datasources/mock_data_source.dart';
import 'package:taskflow/domain/entities/enums.dart';
import 'package:taskflow/domain/entities/session.dart';
import 'package:taskflow/presentation/auth/auth_controller.dart';
import 'package:taskflow/presentation/providers.dart';

/// Reads the real asset from disk so tests exercise the same JSON the app
/// ships, without needing the asset bundle.
Future<String> loadMockJson() async {
  return _cachedMockJson ??= await File(
    'assets/data/mock_data.json',
  ).readAsString();
}

String? _cachedMockJson;

/// Loads the asset once so widget tests can build a data source that resolves
/// without real file I/O — `pump` cannot drive a disk read to completion.
Future<void> preloadMockJson() => loadMockJson();

/// The already-loaded asset. Call [preloadMockJson] in `setUpAll` first.
String get mockJson {
  final json = _cachedMockJson;
  if (json == null) {
    throw StateError('Call preloadMockJson() in setUpAll() first');
  }
  return json;
}

/// A [MockDataSource] with no artificial latency, backed by the real asset.
MockDataSource testDataSource({
  DevSettings Function()? devSettings,
  String? overrideJson,
}) {
  return MockDataSource(
    devSettings: devSettings,
    loadAsset: () async => overrideJson ?? await loadMockJson(),
    latency: Duration.zero,
  );
}

/// A data source backed by the preloaded JSON, so no future needs real I/O.
/// Widget tests must use this: `pump` cannot advance a disk read.
MockDataSource syncDataSource({
  DevSettings Function()? devSettings,
  String? overrideJson,
}) {
  final json = overrideJson ?? mockJson;
  return MockDataSource(
    devSettings: devSettings,
    loadAsset: () => SynchronousFuture(json),
    latency: Duration.zero,
  );
}

/// A container wired with in-memory storage and a zero-latency data source.
///
/// [now] pins the clock so due-date and token-expiry assertions are stable.
ProviderContainer testContainer({
  DateTime? now,
  LocalStore? localStore,
  SecureStore? secureStore,
  MockDataSource? dataSource,
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWithValue(localStore ?? InMemoryLocalStore()),
      secureStoreProvider.overrideWithValue(
        secureStore ?? InMemorySecureStore(),
      ),
      if (dataSource != null)
        mockDataSourceProvider.overrideWithValue(dataSource),
      if (dataSource == null)
        mockDataSourceProvider.overrideWith(
          (ref) => syncDataSource(
            devSettings: () => ref.read(devSettingsProvider),
          ),
        ),
      if (now != null) clockProvider.overrideWithValue(() => now),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Signs a container in as one of the seeded accounts.
Future<Session> signIn(
  ProviderContainer container, {
  String email = adminEmail,
  String password = testPassword,
}) async {
  final ok = await container
      .read(authControllerProvider.notifier)
      .login(email: email, password: password);
  if (!ok) {
    throw StateError(
      'Test sign-in failed: ${container.read(authControllerProvider).error}',
    );
  }
  return container.read(sessionProvider);
}

/// Signs in from inside a `testWidgets` body.
///
/// A bare `await signIn(...)` deadlocks under `testWidgets`: the data source
/// awaits a timer that only advances when the tester pumps. This drives the
/// clock until the login future completes.
Future<Session> signInWidget(
  WidgetTester tester,
  ProviderContainer container, {
  String email = adminEmail,
  String password = testPassword,
}) async {
  final pending = container
      .read(authControllerProvider.notifier)
      .login(email: email, password: password);

  // Pump until the login settles; the bound stops a genuine hang from
  // spinning forever.
  var ok = false;
  for (var i = 0; i < 40 && !ok; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    ok = container.read(authControllerProvider).isAuthenticated;
  }
  await pending;

  if (!container.read(authControllerProvider).isAuthenticated) {
    throw StateError(
      'Test sign-in failed: ${container.read(authControllerProvider).error}',
    );
  }
  return container.read(sessionProvider);
}

/// Seeded credentials, read from the asset so the tests stay in step with the
/// mock data rather than duplicating it.
const adminEmail = 'ava.admin@nimbusdigital.test';
const memberEmail = 'marcus.member@nimbusdigital.test';
const otherOrgAdminEmail = 'daniel.admin@harborlightstudios.test';
const otherOrgMemberEmail = 'elena.member@harborlightstudios.test';
const testPassword = 'Password123!';

/// Ids present in the seed data, used by tests that assert on known rows.
abstract final class Seed {
  static const nimbusOrgId = 'org_a1b2c3';
  static const harborlightOrgId = 'org_d4e5f6';

  static const avaId = 'user_001';
  static const marcusId = 'user_002';
  static const priyaId = 'user_003';
  static const danielId = 'user_004';
  static const elenaId = 'user_005';

  static const websiteProjectId = 'proj_1001';
  static const mobileProjectId = 'proj_1002';
  static const onboardingProjectId = 'proj_1003';

  static const navTaskId = 'task_2002';
  static const seoTaskId = 'task_2005';
  static const onboardingTaskId = 'task_2012';
}

/// A session built directly, for unit tests that do not need a login round trip.
Session sessionFor({
  String userId = Seed.avaId,
  String orgId = Seed.nimbusOrgId,
  OrgRole role = OrgRole.orgAdmin,
}) {
  return Session(
    userId: userId,
    name: 'Test User',
    email: 'test@example.test',
    orgId: orgId,
    orgName: 'Test Org',
    role: role,
  );
}

/// Wraps a widget with the providers and theme the app supplies at runtime.
Widget wrapWithApp(Widget child, {required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

/// Convenience for building a data source over an edited copy of the seed
/// data, e.g. to produce an empty-list case.
Future<String> mockJsonWith(
  Map<String, dynamic> Function(Map<String, dynamic>) edit,
) async {
  final json = jsonDecode(await loadMockJson()) as Map<String, dynamic>;
  return jsonEncode(edit(json));
}
