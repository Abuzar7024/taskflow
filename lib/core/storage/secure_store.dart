import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/session.dart';

/// Persists the token pair and the session descriptor.
///
/// Passwords are never written here — only tokens issued by the (mock) auth
/// endpoint and the non-sensitive session descriptor.
abstract interface class SecureStore {
  Future<AuthTokens?> readTokens();
  Future<void> writeTokens(AuthTokens tokens);
  Future<Session?> readSession();
  Future<void> writeSession(Session session);
  Future<void> clear();
}

class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;

  static const _tokensKey = 'taskflow.tokens';
  static const _sessionKey = 'taskflow.session';

  @override
  Future<AuthTokens?> readTokens() async {
    final raw = await _storage.read(key: _tokensKey);
    if (raw == null) return null;
    return _decode(raw, AuthTokens.fromJson, _tokensKey);
  }

  @override
  Future<void> writeTokens(AuthTokens tokens) {
    return _storage.write(key: _tokensKey, value: jsonEncode(tokens.toJson()));
  }

  @override
  Future<Session?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    return _decode(raw, Session.fromJson, _sessionKey);
  }

  @override
  Future<void> writeSession(Session session) {
    return _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokensKey);
    await _storage.delete(key: _sessionKey);
  }

  /// A payload written by an older build can no longer be parsable. Dropping
  /// it signs the user out cleanly instead of wedging the app on launch.
  Future<T?> _decode<T>(
    String raw,
    T Function(Map<String, dynamic>) parse,
    String key,
  ) async {
    try {
      return parse(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await _storage.delete(key: key);
      return null;
    }
  }
}

/// In-memory implementation used by tests and by the widget-test harness,
/// where the platform channel is unavailable.
class InMemorySecureStore implements SecureStore {
  AuthTokens? _tokens;
  Session? _session;

  @override
  Future<AuthTokens?> readTokens() async => _tokens;

  @override
  Future<void> writeTokens(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<Session?> readSession() async => _session;

  @override
  Future<void> writeSession(Session session) async => _session = session;

  @override
  Future<void> clear() async {
    _tokens = null;
    _session = null;
  }
}
