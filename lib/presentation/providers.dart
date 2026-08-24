import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/dev_settings.dart';
import '../core/storage/local_store.dart';
import '../core/storage/secure_store.dart';
import '../data/datasources/mock_data_source.dart';
import '../data/repositories/mock_repositories.dart';
import '../data/repositories/offline_cache.dart';
import '../domain/repositories/repositories.dart';

/// Composition root. Overridden in `main()` with the real storage
/// implementations and in tests with in-memory ones.
final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('localStoreProvider must be overridden');
});

final secureStoreProvider = Provider<SecureStore>((ref) {
  throw UnimplementedError('secureStoreProvider must be overridden');
});

/// Reviewer-facing failure switches. Persisted so they survive a restart.
class DevSettingsController extends StateNotifier<DevSettings> {
  DevSettingsController(this._store)
    : super(
        DevSettings.fromJson(
          _store.getJson(StorageKeys.devSettings) ?? const {},
        ),
      );

  final LocalStore _store;

  void setFailure(SimulatedFailure failure) =>
      _persist(state.copyWith(failure: failure));

  void setOffline(bool offline) => _persist(state.copyWith(offline: offline));

  void setSlowNetwork(bool slow) => _persist(state.copyWith(slowNetwork: slow));

  void reset() => _persist(const DevSettings());

  void _persist(DevSettings next) {
    state = next;
    _store.setJson(StorageKeys.devSettings, next.toJson());
  }
}

final devSettingsProvider =
    StateNotifierProvider<DevSettingsController, DevSettings>((ref) {
      return DevSettingsController(ref.watch(localStoreProvider));
    });

/// True when the app is in simulated offline mode.
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(devSettingsProvider.select((s) => s.offline));
});

final mockDataSourceProvider = Provider<MockDataSource>((ref) {
  // Read (not watch) inside the callback so toggling a dev switch changes
  // behaviour of the next request without rebuilding the whole data layer.
  return MockDataSource(devSettings: () => ref.read(devSettingsProvider));
});

final offlineCacheProvider = Provider<OfflineCache>((ref) {
  return OfflineCache(ref.watch(localStoreProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository(ref.watch(mockDataSourceProvider));
});

final projectRepositoryProvider = Provider<MockProjectRepository>((ref) {
  return MockProjectRepository(
    ref.watch(mockDataSourceProvider),
    ref.watch(offlineCacheProvider),
  );
});

final taskRepositoryProvider = Provider<MockTaskRepository>((ref) {
  return MockTaskRepository(
    ref.watch(mockDataSourceProvider),
    ref.watch(offlineCacheProvider),
  );
});

final orgRepositoryProvider = Provider<OrgRepository>((ref) {
  return MockOrgRepository(ref.watch(mockDataSourceProvider));
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return MockCommentRepository(ref.watch(mockDataSourceProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return MockNotificationRepository(ref.watch(mockDataSourceProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return MockUserRepository(ref.watch(mockDataSourceProvider));
});

/// Theme preference, persisted across launches.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._store) : super(_read(_store));

  final LocalStore _store;

  static ThemeMode _read(LocalStore store) {
    return switch (store.getString(StorageKeys.themeMode)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void set(ThemeMode mode) {
    state = mode;
    _store.setString(StorageKeys.themeMode, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
      return ThemeModeController(ref.watch(localStoreProvider));
    });

/// Injected so tests can pin "now" when asserting overdue/relative dates.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
