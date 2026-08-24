import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/storage/secure_store.dart';
import '../../data/repositories/offline_cache.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/repositories.dart';
import '../providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.session,
    this.isSubmitting = false,
    this.error,
  });

  final AuthStatus status;
  final Session? session;

  /// True while a login/registration request is in flight, so the form can
  /// lock its submit button.
  final bool isSubmitting;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    Session? session,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, session, isSubmitting, error];
}

/// Owns the session: restore on launch, login, register, refresh, logout.
class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required SecureStore secureStore,
    required OfflineCache cache,
    required DateTime Function() clock,
  }) : _repository = repository,
       _secureStore = secureStore,
       _cache = cache,
       _clock = clock,
       super(const AuthState());

  final AuthRepository _repository;
  final SecureStore _secureStore;
  final OfflineCache _cache;
  final DateTime Function() _clock;

  AuthTokens? _tokens;
  Future<void>? _inFlightRefresh;

  /// Visible for tests that assert refresh behaviour.
  AuthTokens? get tokens => _tokens;

  /// Restores a stored session on launch. A missing or fully expired token
  /// pair lands the user on login instead of a half-authenticated state.
  Future<void> restore() async {
    final stored = await _secureStore.readTokens();
    final session = await _secureStore.readSession();

    if (stored == null || session == null) {
      await _clearLocalState();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    if (stored.isRefreshTokenExpired(_clock())) {
      await _clearLocalState();
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Your session expired. Please sign in again.',
      );
      return;
    }

    _tokens = stored;
    state = AuthState(status: AuthStatus.authenticated, session: session);
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _repository.login(email: email, password: password);
      await _persist(result.session, result.tokens);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      await _persist(result.session, result.tokens);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    }
  }

  /// Ensures a usable access token before a protected call.
  ///
  /// Concurrent callers share a single refresh so a burst of requests cannot
  /// trigger a burst of refreshes.
  Future<void> ensureValidAccessToken() {
    final tokens = _tokens;
    if (tokens == null) return Future.value();
    if (!tokens.isAccessTokenExpired(_clock())) return Future.value();
    return _inFlightRefresh ??= _refresh().whenComplete(
      () => _inFlightRefresh = null,
    );
  }

  Future<void> _refresh() async {
    final tokens = _tokens;
    if (tokens == null) return;

    if (tokens.isRefreshTokenExpired(_clock())) {
      await logout(message: 'Your session expired. Please sign in again.');
      return;
    }

    try {
      final refreshed = await _repository.refresh(tokens.refreshToken);
      _tokens = refreshed;
      await _secureStore.writeTokens(refreshed);
    } on AppException {
      await logout(message: 'Your session expired. Please sign in again.');
    }
  }

  /// Called when a repository reports 401 so the session does not linger.
  Future<void> handleUnauthorized() async {
    await ensureValidAccessToken();
    if (state.isAuthenticated) {
      await logout(message: 'Your session expired. Please sign in again.');
    }
  }

  Future<void> logout({String? message}) async {
    await _clearLocalState();
    state = AuthState(status: AuthStatus.unauthenticated, error: message);
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> _persist(Session session, AuthTokens tokens) async {
    _tokens = tokens;
    await _secureStore.writeTokens(tokens);
    await _secureStore.writeSession(session);
    state = AuthState(status: AuthStatus.authenticated, session: session);
  }

  /// Clears tokens, session and every cached org payload, so a second user on
  /// the same device never sees the previous user's data.
  Future<void> _clearLocalState() async {
    _tokens = null;
    await _secureStore.clear();
    await _cache.clearAll();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
      return AuthController(
        repository: ref.watch(authRepositoryProvider),
        secureStore: ref.watch(secureStoreProvider),
        cache: ref.watch(offlineCacheProvider),
        clock: ref.watch(clockProvider),
      );
    });

/// The active session for screens behind the auth guard.
///
/// On logout the authenticated screens rebuild one last time before the
/// router redirect swaps them out. Retaining the previous session for that
/// final frame keeps those widgets from throwing on a null read; the router
/// then unmounts them.
final sessionProvider = Provider<Session>((ref) {
  final session = ref.watch(authControllerProvider).session;
  if (session != null) {
    _lastSession = session;
    return session;
  }

  final previous = _lastSession;
  if (previous != null) return previous;

  throw StateError('sessionProvider read before any session existed');
});

/// Last non-null session, kept only so authenticated screens can complete
/// their final rebuild after logout without a null read.
Session? _lastSession;

/// Runs an authenticated read: refreshes a stale access token first, and
/// signs the user out if the server rejects the token.
///
/// Without this a 401 on a read would leave the user staring at an error
/// screen while still nominally signed in.
Future<T> authenticatedRead<T>(Ref ref, Future<T> Function() read) async {
  final auth = ref.read(authControllerProvider.notifier);
  await auth.ensureValidAccessToken();
  try {
    return await read();
  } on UnauthorizedException {
    await auth.handleUnauthorized();
    rethrow;
  }
}
