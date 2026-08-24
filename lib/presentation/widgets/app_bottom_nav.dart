import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class NavItem {
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
}

/// The bottom navigation bar.
///
/// Custom rather than Material's `NavigationBar` so the active state is a
/// small underline instead of a heavy filled pill — the bar supports the
/// content rather than competing with it.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).c;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.c;
    final tone = selected ? c.primary : c.textMuted;

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        // A generous, borderless target: the whole column is tappable.
        splashColor: c.primary.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The active marker sits above the icon and slides in.
            AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.easing,
              height: 3,
              width: selected ? 18 : 0,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _IconWithBadge(
              icon: selected ? item.activeIcon : item.icon,
              tone: tone,
              badgeCount: item.badgeCount,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style:
                  theme.textTheme.labelSmall?.copyWith(
                    color: tone,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ) ??
                  const TextStyle(),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.tone,
    required this.badgeCount,
  });

  final IconData icon;
  final Color tone;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).c;
    final icon0 = Icon(icon, size: 22, color: tone);
    if (badgeCount <= 0) return icon0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon0,
        Positioned(
          top: -3,
          right: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 15),
            decoration: BoxDecoration(
              color: c.error,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: c.surface, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              badgeCount > 9 ? '9+' : '$badgeCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The tablet counterpart: a slim rail with the same visual language.
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.extended = false,
  });

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.c;

    return Container(
      width: extended ? 208 : 78,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: _RailButton(
                  item: items[i],
                  selected: i == selectedIndex,
                  extended: extended,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.item,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.c;
    final tone = selected ? c.primary : c.textMuted;

    return Material(
      color: selected ? c.surfaceAccent : Colors.transparent,
      borderRadius: AppRadius.field,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.field,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              _IconWithBadge(
                icon: selected ? item.activeIcon : item.icon,
                tone: tone,
                badgeCount: item.badgeCount,
              ),
              if (extended) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: tone,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
