import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/session.dart';
import '../auth/auth_controller.dart';
import '../providers.dart';
import '../tasks/task_providers.dart';
import '../widgets/app_illustrations.dart';
import '../widgets/app_settings.dart';
import '../widgets/common.dart';

/// Profile overview: identity, then grouped entry points into the settings
/// screens. Each group is one page section, not a separate card stack.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final c = Theme.of(context).c;
    final themeMode = ref.watch(themeModeProvider);
    final devSettings = ref.watch(devSettingsProvider);
    final memberCount = ref.watch(orgMembersProvider).valueOrNull?.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          children: [
            _ProfileHeader(session: session),
            const SizedBox(height: AppSpacing.xl),

            AppSection(
              title: 'Account',
              children: [
                AppSettingsTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile information',
                  onTap: () => context.push(Routes.accountSettings),
                ),
                AppSettingsTile(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: session.role.label,
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            AppSection(
              title: 'Workspace',
              children: [
                AppSettingsTile(
                  icon: Icons.apartment_rounded,
                  label: 'Organization',
                  value: session.orgName,
                  showChevron: false,
                ),
                AppSettingsTile(
                  icon: Icons.group_outlined,
                  label: 'Members',
                  value: memberCount == null ? null : '$memberCount',
                  onTap: () => context.push(Routes.members),
                ),
                AppSettingsTile(
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                  onTap: () => context.go(Routes.projects),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            AppSection(
              title: 'Preferences',
              children: [
                AppSettingsTile(
                  icon: Icons.contrast_rounded,
                  label: 'Theme',
                  value: switch (themeMode) {
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                    ThemeMode.system => 'System',
                  },
                  onTap: () => context.push(Routes.themeSettings),
                ),
                AppSettingsTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  onTap: () => context.push(Routes.notifications),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            AppSection(
              title: 'Security',
              children: [
                AppSettingsTile(
                  icon: Icons.shield_outlined,
                  label: 'Session',
                  onTap: () => context.push(Routes.sessionSettings),
                ),
                AppSettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign out',
                  tone: c.error,
                  showChevron: false,
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            AppSection(
              title: 'Developer',
              description: devSettings.isDefault
                  ? 'Simulate network failures and offline mode to review how '
                        'the app handles them.'
                  : 'Simulation is active — reset it to restore normal '
                        'behaviour.',
              children: [
                AppSettingsTile(
                  icon: Icons.science_outlined,
                  label: 'Developer tools',
                  value: devSettings.isDefault ? null : 'Active',
                  onTap: () => context.push(Routes.developerTools),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to reach your workspace.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed) return;
    await ref.read(authControllerProvider.notifier).logout();
  }
}

/// Identity block: avatar, name, email, and the organization/role pair.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatar(
              user: User(
                id: session.userId,
                name: session.name,
                email: session.email,
                avatarUrl: session.avatarUrl,
              ),
              size: 64,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: theme.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    session.email,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.surfaceAccent,
            borderRadius: AppRadius.card,
          ),
          child: Row(
            children: [
              const AppIllustration(art: AppArt.workspace, size: 52),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.orgName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      session.role.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
