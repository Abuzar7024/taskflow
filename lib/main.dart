import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/local_store.dart';
import 'core/storage/secure_store.dart';
import 'presentation/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferences are read synchronously by several providers, so the instance
  // is created before the first frame.
  final localStore = await PrefsLocalStore.create();

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(localStore),
        secureStoreProvider.overrideWithValue(FlutterSecureStore()),
      ],
      child: const TaskFlowApp(),
    ),
  );
}
