import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../providers.dart';

/// Persistent strip shown while simulated offline mode is on.
///
/// [cachedAt] labels how stale the visible data is, so the user knows they are
/// looking at a snapshot rather than live data.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({this.cachedAt, super.key});

  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isOfflineProvider)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cached = cachedAt;
    final now = ref.watch(clockProvider)();

    return Material(
      color: theme.colorScheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off,
                size: 16,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  cached == null
                      ? 'You are offline. Showing what we have saved.'
                      : 'Offline — showing data from ${Dates.timeAgo(cached, now)}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
