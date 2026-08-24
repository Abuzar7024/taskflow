import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// A titled group of settings rows.
///
/// The heading sits outside the surface, so groups read as sections of one
/// page rather than as a stack of separate cards.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            0,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: c.textMuted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Padding(
                    // Indented divider, aligned with the row's text.
                    padding: const EdgeInsets.only(left: 52),
                    child: Divider(height: 1, color: c.border),
                  ),
                children[i],
              ],
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(description!, style: theme.textTheme.bodySmall),
          ),
        ],
      ],
    );
  }
}

/// One row inside an [AppSection].
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.tone,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;

  /// Current selection, shown at the end of the row.
  final String? value;

  final VoidCallback? onTap;
  final Widget? trailing;

  /// Overrides the icon and label colour, e.g. red for sign out.
  final Color? tone;

  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.c;
    final accent = tone ?? c.textMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tone ?? c.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(value!, style: theme.textTheme.bodyMedium),
              ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null && showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

/// A selectable option row, used by the theme and preference screens.
class AppChoiceTile<T> extends StatelessWidget {
  const AppChoiceTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onSelect,
    this.icon,
    this.description,
  });

  final T value;
  final T groupValue;
  final String label;
  final String? description;
  final IconData? icon;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.c;
    final selected = value == groupValue;

    return InkWell(
      onTap: () => onSelect(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: selected ? c.primary : c.textMuted,
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: c.text,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(description!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            AnimatedScale(
              duration: AppMotion.fast,
              scale: selected ? 1 : 0.6,
              child: AnimatedOpacity(
                duration: AppMotion.fast,
                opacity: selected ? 1 : 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: c.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
