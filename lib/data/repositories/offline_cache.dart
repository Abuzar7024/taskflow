import '../../core/storage/local_store.dart';

/// A cached list plus the time it was written, so the UI can say how stale it is.
class CachedList<T> {
  const CachedList({required this.items, required this.cachedAt});

  final List<T> items;
  final DateTime cachedAt;
}

/// Persists the last successful read per organization so that data stays
/// visible when the app is offline or a request fails.
class OfflineCache {
  const OfflineCache(this._store);

  final LocalStore _store;

  Future<void> write<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    return _store.setJson(key, {
      'cached_at': DateTime.now().toIso8601String(),
      'items': items.map(toJson).toList(),
    });
  }

  /// Returns `null` when nothing is cached or the payload cannot be parsed —
  /// a corrupt cache should degrade to "no cache", never crash a screen.
  CachedList<T>? read<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final json = _store.getJson(key);
    if (json == null) return null;
    try {
      final items = (json['items'] as List)
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
      return CachedList(
        items: items,
        cachedAt: DateTime.parse(json['cached_at'] as String),
      );
    } catch (_) {
      _store.remove(key);
      return null;
    }
  }

  Future<void> clearAll() => _store.removeWhere(StorageKeys.isCacheKey);
}
