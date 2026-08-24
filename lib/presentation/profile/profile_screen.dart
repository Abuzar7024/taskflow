import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/permissions.dart';
import '../auth/auth_controller.dart';
import '../providers.dart';
import '../tasks/task_providers.dart';
import '../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final devSettings = ref.watch(devSettingsProvider);
    final members = ref.watch(orgMembersProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                  UserAvatar(
                    user: User(
                      id: session.userId,
                      name: session.name,
                      email: session.email,
                      avatarUrl: session.avatarUrl,
                    ),
                    radius: 28,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          session.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Organization'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.apartment,
                  label: 'Organization',
                  value: session.orgName,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: session.isAdmin
                      ? Icons.shield_outlined
                      : Icons.person_outline,
                  label: 'Your role',
                  value: session.role.label,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.groups_outlined,
                  label: 'Members',
                  value: members == null ? '—' : '${members.length}',
                ),
                if (Permissions.canManageMembers(session)) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'As an admin you can delete projects and manage members.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (value) => ref
                  .read(themeModeProvider.notifier)
                  .set(value ?? ThemeMode.system),
              child: Column(
                children: [
                  for (final mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(switch (mode) {
                        ThemeMode.system => 'Match system',
                        ThemeMode.light => 'Light',
                        ThemeMode.dark => 'Dark',
                      }),
                      dense: true,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Developer'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Developer tools'),
              subtitle: Text(
                devSettings.isDefault
                    ? 'Simulate offline mode and errors'
                    : 'Simulation active',
                style: TextStyle(
                  color: devSettings.isDefault
                      ? null
                      : theme.colorScheme.tertiary,
                  fontWeight: devSettings.isDefault ? null : FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.developerTools),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: Icon(Icons.logout, size: 18, color: theme.colorScheme.error),
            label: Text(
              'Sign out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out?',
      message:
          'You will need to sign in again to see your projects and tasks.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed) return;
    await ref.read(authControllerProvider.notifier).logout();
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
