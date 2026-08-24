import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/enums.dart';
import '../auth/auth_controller.dart';
import '../providers.dart';
import '../tasks/task_providers.dart';
import '../widgets/app_settings.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';

/// Shared frame for a settings sub-screen: a title, a one-line explanation of
/// what the page controls, then its sections.
class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.xl,
            ),
            child: Text(description, style: theme.textTheme.bodyMedium),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Read-only account details. The mock backend has no update endpoint, so the
/// screen states that rather than offering a field that cannot save.
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return _SettingsScaffold(
      title: 'Profile information',
      description: 'The details your teammates see across the workspace.',
      children: [
        AppSection(
          title: 'Identity',
          children: [
            AppSettingsTile(
              icon: Icons.person_outline_rounded,
              label: 'Name',
              value: session.name,
              showChevron: false,
            ),
            AppSettingsTile(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: session.email,
              showChevron: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSection(
          title: 'Membership',
          description:
              'Profile details come from your organization and cannot be '
              'edited from the app.',
          children: [
            AppSettingsTile(
              icon: Icons.apartment_rounded,
              label: 'Organization',
              value: session.orgName,
              showChevron: false,
            ),
            AppSettingsTile(
              icon: Icons.badge_outlined,
              label: 'Role',
              value: session.role.label,
              showChevron: false,
            ),
          ],
        ),
      ],
    );
  }
}

/// Theme choice: light, dark, or follow the device.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final controller = ref.read(themeModeProvider.notifier);

    return _SettingsScaffold(
      title: 'Theme',
      description: 'Choose how TaskFlow looks, or let it follow your device.',
      children: [
        AppSection(
          title: 'Appearance',
          children: [
            AppChoiceTile(
              value: ThemeMode.system,
              groupValue: mode,
              icon: Icons.brightness_auto_rounded,
              label: 'System',
              description: 'Match your device setting',
              onSelect: controller.set,
            ),
            AppChoiceTile(
              value: ThemeMode.light,
              groupValue: mode,
              icon: Icons.light_mode_outlined,
              label: 'Light',
              onSelect: controller.set,
            ),
            AppChoiceTile(
              value: ThemeMode.dark,
              groupValue: mode,
              icon: Icons.dark_mode_outlined,
              label: 'Dark',
              onSelect: controller.set,
            ),
          ],
        ),
      ],
    );
  }
}

/// Session and token state, plus sign-out.
class SessionSettingsScreen extends ConsumerWidget {
  const SessionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final tokens = ref.watch(authControllerProvider.notifier).tokens;
    final now = ref.watch(clockProvider)();
    final c = Theme.of(context).c;

    return _SettingsScaffold(
      title: 'Session',
      description: 'How you are signed in on this device.',
      children: [
        AppSection(
          title: 'Signed in as',
          children: [
            AppSettingsTile(
              icon: Icons.person_outline_rounded,
              label: session.name,
              value: session.role.label,
              showChevron: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSection(
          title: 'Access',
          description:
              'Tokens are held in secure storage and refresh automatically. '
              'Signing out clears them along with any cached workspace data.',
          children: [
            AppSettingsTile(
              icon: Icons.key_outlined,
              label: 'Access token',
              value: tokens == null
                  ? '—'
                  : tokens.isAccessTokenExpired(now)
                  ? 'Refreshing'
                  : 'Valid',
              showChevron: false,
            ),
            AppSettingsTile(
              icon: Icons.schedule_rounded,
              label: 'Expires',
              value: tokens == null
                  ? '—'
                  : Dates.timeAgo(tokens.accessTokenExpiresAt, now),
              showChevron: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSection(
          title: 'Danger zone',
          children: [
            AppSettingsTile(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              tone: c.error,
              showChevron: false,
              onTap: () async {
                final confirmed = await confirmAction(
                  context,
                  title: 'Sign out?',
                  message:
                      'You will need to sign in again to reach your workspace.',
                  confirmLabel: 'Sign out',
                );
                if (!confirmed) return;
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// The organization's members and their roles.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(orgMembersProvider);
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: members.when(
        loading: () => const SkeletonList(count: 4, lines: 0),
        error: (error, _) => ErrorStateView(
          message: messageFor(error),
          onRetry: () => ref.invalidate(orgMembersProvider),
        ),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          itemCount: items.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.md,
                ),
                child: Text(
                  '${items.length} people in ${session.orgName}',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            final member = items[index - 1];
            final isYou = member.user.id == session.userId;

            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  UserAvatar(user: member.user, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.user.name,
                                style: theme.textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isYou) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Text('You', style: theme.textTheme.labelSmall),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          member.user.email,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppChip(
                    label: member.role == OrgRole.orgAdmin ? 'Admin' : 'Member',
                    tone: member.role == OrgRole.orgAdmin
                        ? theme.c.primary
                        : theme.c.textMuted,
                    dense: true,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
