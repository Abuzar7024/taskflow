import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/errors/app_exception.dart';
import 'package:taskflow/core/storage/secure_store.dart';
import 'package:taskflow/data/repositories/offline_cache.dart';
import 'package:taskflow/core/storage/local_store.dart';
import 'package:taskflow/domain/entities/enums.dart';
import 'package:taskflow/domain/entities/session.dart';
import 'package:taskflow/domain/repositories/repositories.dart';
import 'package:taskflow/presentation/auth/auth_controller.dart';

import '../support/harness.dart';

/// A controllable clock so token expiry can be advanced without waiting.
class _TestClock {
  _TestClock(this._now);

  DateTime _now;

  DateTime call() => _now;

  void advance(Duration duration) => _now = _now.add(duration);
}

/// Records refresh calls and can be told to fail, so the refresh and
/// forced-logout paths are both reachable.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._clock);

  final _TestClock _clock;

  int refreshCount = 0;
  bool refreshFails = false;

  static const _session = Session(
    userId: 'user_001',
    name: 'Ava Thompson',
    email: 'ava.admin@nimbusdigital.test',
    orgId: 'org_a1b2c3',
    orgName: 'Nimbus Digital',
    role: OrgRole.orgAdmin,
  );

  @override
  Future<({Session session, AuthTokens tokens})> login({
    required String email,
    required String password,
  }) async {
    if (password != testPassword) throw const InvalidCredentialsException();
    return (session: _session, tokens: _issue());
  }

  @override
  Future<({Session session, AuthTokens tokens})> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return (session: _session, tokens: _issue());
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    refreshCount++;
    if (refreshFails) throw const UnauthorizedException();
    return _issue();
  }

  AuthTokens _issue() {
    return AuthTokens.fromLifetimes(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessTokenLifetimeSeconds: 900,
      refreshTokenLifetimeSeconds: 604800,
      issuedAt: _clock(),
    );
  }
}

AuthController _buildController({
  required _TestClock clock,
  required _FakeAuthRepository repository,
  SecureStore? store,
}) {
  return AuthController(
    repository: repository,
    secureStore: store ?? InMemorySecureStore(),
    cache: OfflineCache(InMemoryLocalStore()),
    clock: clock.call,
  );
}

void main() {
  late _TestClock clock;
  late _FakeAuthRepository repository;

  setUp(() {
    clock = _TestClock(DateTime(2026, 8, 23, 10));
    repository = _FakeAuthRepository(clock);
  });

  group('login', () {
    test('stores the session and tokens on success', () async {
      final store = InMemorySecureStore();
      final controller = _buildController(
        clock: clock,
        repository: repository,
        store: store,
      );

      final ok = await controller.login(
        email: adminEmail,
        password: testPassword,
      );

      expect(ok, isTrue);
      expect(controller.state.status, AuthStatus.authenticated);
      expect(controller.state.session?.email, adminEmail);
      expect(await store.readTokens(), isNotNull);
      expect(await store.readSession(), isNotNull);
    });

    test('surfaces a message and stays signed out on bad credentials', () async {
      final controller = _buildController(clock: clock, repository: repository);

      final ok = await controller.login(
        email: adminEmail,
        password: 'wrong-password',
      );

      expect(ok, isFalse);
      expect(controller.state.status, isNot(AuthStatus.authenticated));
      expect(controller.state.error, isNotNull);
      expect(controller.state.isSubmitting, isFalse);
    });

    test('clears a previous error when a new attempt starts', () async {
      final controller = _buildController(clock: clock, repository: repository);
      await controller.login(email: adminEmail, password: 'wrong');
      expect(controller.state.error, isNotNull);

      await controller.login(email: adminEmail, password: testPassword);
      expect(controller.state.error, isNull);
    });
  });

  group('restore', () {
    test('signs out when nothing is stored', () async {
      final controller = _buildController(clock: clock, repository: repository);
      await controller.restore();
      expect(controller.state.status, AuthStatus.unauthenticated);
    });

    test('restores a stored session with a live refresh token', () async {
      final store = InMemorySecureStore();
      final first = _buildController(
        clock: clock,
        repository: repository,
        store: store,
      );
      await first.login(email: adminEmail, password: testPassword);

      final restored = _buildController(
        clock: clock,
        repository: repository,
        store: store,
      );
      await restored.restore();

      expect(restored.state.status, AuthStatus.authenticated);
      expect(restored.state.session?.email, adminEmail);
    });

    test('signs out when the refresh token has expired', () async {
      final store = InMemorySecureStore();
      final first = _buildController(
        clock: clock,
        repository: repository,
        store: store,
      );
      await first.login(email: adminEmail, password: testPassword);

      // Refresh lifetime is 7 days in the mock response.
      clock.advance(const Duration(days: 8));

      final restored = _buildController(
        clock: clock,
        repository: repository,
        store: store,
      );
      await restored.restore();

      expect(restored.state.status, AuthStatus.unauthenticated);
      expect(restored.state.error, isNotNull);
      expect(await store.readTokens(), isNull);
    });
  });

  group('token refresh', () {
    test('does not refresh while the access token is valid', () async {
      final controller = _buildController(clock: clock, repository: repository);
      await controller.login(email: adminEmail, password: testPassword);

      await controller.ensureValidAccessToken();

      expect(repository.refreshCount, 0);
    });

    test('refreshes once the access token has expired', () async {
      final controller = _buildController(clock: clock, repository: repository);
      await controller.login(email: adminEmail, password: testPassword);

      // Access lifetime is 900s in the mock response.
      clock.advance(const Duration(minutes: 16));
      await controller.ensureValidAccessToken();

      expect(repository.refreshCount, 1);
      expect(controller.state.status, AuthStatus.authenticated);
    });

    test('refreshes early, inside the leeway window', () async {
      final controller = _buildController(clock: clock, repository: repository);
      await controller.login(email: adminEmail, password: testPassword);

      // 890s in: not yet expired, but inside the 30s leeway.
      clock.advance(const Duration(seconds: 890));
      await controller.ensureValidAccessToken();

      expect(repository.refreshCount, 1);
    });

    test('concurrent callers share a single refresh', () async {
      final controller = _buildController(clock: clock, repository: repository);
      await controller.login(email: adminEmail, password: testPassword);
      clock.advance(const Duration(minutes: 16));

      await Future.wait([
        controller.ensureValidAccessToken(),
        controller.ensureValidAccessToken(),
        controller.ensureValidAccessToken(),
      ]);

      expect(repository.refreshCount, 1);
    });

    test('persists the refreshed tokens', () async {
      final store = InMemorySecureStore();
      final controller = _buildController(
        clock: clock,
        repository: repository,
        store: store,
      );
      await controller.login(email: adminEmail, password: testPassword);
      final original = await store.readTokens();

      clock.advance(const Duration(minutes: 16));
      await controller.ensureValidAccessToken();

      final updated = await store.readTokens();
      expect(
        updated!.accessTokenExpiresAt.isAfter(original!.accessTokenExpiresAt),
        isTrue,
      );
    });

    test('a failing refresh forces logout and clears storage', () async {
      final store = InMemorySecureStore();
      final controller = _buildController(
        clock: clock,
        repository: repository,
        store: store,
      );
      await controller.login(email: adminEmail, password: testPassword);

      repository.refreshFails = true;
      clock.advance(const Duration(minutes: 16));
      await controller.ensureValidAccessToken();

      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.error, isNotNull);
      expect(await store.readTokens(), isNull);
      expect(await store.readSession(), isNull);
    });

    test('an expired refresh token logs out without calling the server', () async {
      final controller = _buildController(clock: clock, repository: repository);
      await controller.login(email: adminEmail, password: testPassword);

      clock.advance(const Duration(days: 8));
      await controller.ensureValidAccessToken();

      expect(repository.refreshCount, 0);
      expect(controller.state.status, AuthStatus.unauthenticated);
    });
  });

  group('logout', () {
    test('clears session, tokens and cached data', () async {
      final store = InMemorySecureStore();
      final localStore = InMemoryLocalStore();
      final controller = AuthController(
        repository: repository,
        secureStore: store,
        cache: OfflineCache(localStore),
        clock: clock.call,
      );

      await controller.login(email: adminEmail, password: testPassword);
      await localStore.setJson(StorageKeys.projects('org_a1b2c3'), {
        'cached_at': clock().toIso8601String(),
        'items': <Map<String, dynamic>>[],
      });

      await controller.logout();

      expect(controller.state.status, AuthStatus.unauthenticated);
      expect(controller.state.session, isNull);
      expect(await store.readTokens(), isNull);
      expect(localStore.getJson(StorageKeys.projects('org_a1b2c3')), isNull);
    });
  });

  group('AuthTokens', () {
    test('never exposes token values in toString', () {
      final tokens = AuthTokens.fromLifetimes(
        accessToken: 'super-secret-access',
        refreshToken: 'super-secret-refresh',
        accessTokenLifetimeSeconds: 900,
        refreshTokenLifetimeSeconds: 604800,
        issuedAt: clock(),
      );

      expect(tokens.toString(), isNot(contains('super-secret-access')));
      expect(tokens.toString(), isNot(contains('super-secret-refresh')));
    });

    test('round-trips through JSON', () {
      final tokens = AuthTokens.fromLifetimes(
        accessToken: 'a',
        refreshToken: 'r',
        accessTokenLifetimeSeconds: 900,
        refreshTokenLifetimeSeconds: 604800,
        issuedAt: clock(),
      );

      expect(AuthTokens.fromJson(tokens.toJson()), equals(tokens));
    });
  });
}
