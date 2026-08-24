import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/dev_settings.dart';
import '../../core/theme/app_theme.dart';
import '../providers.dart';
import '../widgets/common.dart';

/// Lets a reviewer force the failure and offline states without editing code.
/// Every switch here is documented in the README.
class DeveloperToolsScreen extends ConsumerWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(devSettingsProvider);
    final controller = ref.read(devSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer tools'),
        actions: [
          if (!settings.isDefault)
            TextButton(
              onPressed: () {
                controller.reset();
                showAppSnackBar(context, 'Simulation reset.');
              },
              child: const Text('Reset'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'These switches change how the mock backend responds, so '
                      'you can see the loading, empty, error and offline states.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Connection'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.offline,
                  onChanged: controller.setOffline,
                  title: const Text('Offline mode'),
                  subtitle: const Text(
                    'Reads fall back to cached data; changes are blocked.',
                  ),
                  secondary: const Icon(Icons.cloud_off),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.slowNetwork,
                  onChanged: controller.setSlowNetwork,
                  title: const Text('Slow network'),
                  subtitle: const Text(
                    'Adds a long delay so loading states stay visible.',
                  ),
                  secondary: const Icon(Icons.hourglass_bottom),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Simulated failure'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: RadioGroup<SimulatedFailure>(
              groupValue: settings.failure,
              onChanged: (value) =>
                  controller.setFailure(value ?? SimulatedFailure.none),
              child: Column(
                children: [
                  for (final failure in SimulatedFailure.values) ...[
                    if (failure != SimulatedFailure.values.first)
                      const Divider(height: 1),
                    RadioListTile<SimulatedFailure>(
                      value: failure,
                      title: Text(failure.label),
                      subtitle: Text(failure.description),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
