import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive key/value storage: cached org data and user settings.
abstract interface class LocalStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Map<String, dynamic>? getJson(String key);
  Future<void> setJson(String key, Map<String, dynamic> value);
  Future<void> remove(String key);

  /// Removes every key under [prefix]. Used to drop a single org's cache.
  Future<void> removeWhere(bool Function(String key) test);
}

class PrefsLocalStore implements LocalStore {
  PrefsLocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsLocalStore> create() async {
    return PrefsLocalStore(await SharedPreferences.getInstance());
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Cache written by an older schema; drop it rather than crash.
      _prefs.remove(key);
      return null;
    }
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<void> removeWhere(bool Function(String key) test) async {
    for (final key in _prefs.getKeys().where(test).toList()) {
      await _prefs.remove(key);
    }
  }
}

class InMemoryLocalStore implements LocalStore {
  final Map<String, String> _values = {};

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async => _values[key] = value;

  @override
  Map<String, dynamic>? getJson(String key) {
    final raw = _values[key];
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _values.remove(key);
      return null;
    }
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async =>
      _values[key] = jsonEncode(value);

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> removeWhere(bool Function(String key) test) async {
    _values.removeWhere((key, _) => test(key));
  }
}

abstract final class StorageKeys {
  static const themeMode = 'taskflow.settings.theme_mode';
  static const devSettings = 'taskflow.dev.settings';

  static const _cachePrefix = 'taskflow.cache.';

  static String projects(String orgId) => '${_cachePrefix}projects.$orgId';

  static String tasks(String orgId) => '${_cachePrefix}tasks.$orgId';

  static bool isCacheKey(String key) => key.startsWith(_cachePrefix);
}
