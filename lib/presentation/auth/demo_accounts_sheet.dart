import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers.dart';
import '../widgets/state_views.dart';

/// Lets a reviewer fill the login form from the seeded accounts.
///
/// The credentials come from the mock data source, so this screen never
/// hardcodes an email or password.
Future<MockCredential?> showDemoAccountsSheet(BuildContext context) {
  return showModalBottomSheet<MockCredential>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _DemoAccountsSheet(),
  );
}

class _DemoAccountsSheet extends ConsumerWidget {
  const _DemoAccountsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accounts = ref.watch(demoAccountsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demo accounts', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pick an account to fill the sign-in form.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            accounts.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: LoadingView(),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'We could not load the demo accounts.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              data: (items) => Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final account = items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          account.role.isAdmin
                              ? Icons.shield_outlined
                              : Icons.person_outline,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        account.email,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(account.role.label),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pop(account),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The seeded credentials, exposed for the demo picker only.
final demoAccountsProvider = FutureProvider.autoDispose<List<MockCredential>>((
  ref,
) {
  return ref.watch(mockDataSourceProvider).testCredentials();
});
