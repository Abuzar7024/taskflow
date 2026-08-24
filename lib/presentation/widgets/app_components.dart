import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// The shared component vocabulary. Screens compose these rather than styling
/// containers inline, so spacing, radii and elevation stay consistent.

/// A layered surface with a soft border and ambient shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.elevated = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).c;

    final decorated = AnimatedContainer(
      duration: AppMotion.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: elevated ? c.surfaceRaised : c.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor ?? c.border),
        boxShadow: elevated ? c.softShadow : null,
      ),
      child: child,
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: decorated,
      ),
    );
  }
}

/// A compact status/priority label. [tone] drives both the text and the tint.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    Color? tone,
    Color? color,
    this.icon,
    this.dense = false,
  }) : tone = tone ?? color ?? AppColors.mutedText;

  final String label;
  final Color tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? AppSpacing.xxs : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.c.wash(tone),
        borderRadius: AppRadius.chip,
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: tone),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
                ?.copyWith(color: tone, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Circular avatar that falls back to initials — remote images will not load
/// offline, so the fallback is the common path rather than an edge case.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 40,
    this.tone,
  });

  final String initials;
  final String? imageUrl;
  final double size;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tone ?? theme.colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.c.wash(accent),
        image: imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
      ),
      alignment: Alignment.center,
      child: imageUrl != null
          ? null
          : Text(
              initials,
              style: theme.textTheme.labelMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.36,
              ),
            ),
    );
  }
}

/// Overlapping avatars used to hint at project membership.
class AppAvatarStack extends StatelessWidget {
  const AppAvatarStack({
    super.key,
    required this.initials,
    this.max = 3,
    this.size = 28,
  });

  final List<String> initials;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = initials.take(max).toList();
    final overflow = initials.length - shown.length;
    final overlap = size * 0.32;

    return SizedBox(
      height: size,
      width: shown.isEmpty
          ? 0
          : size + (shown.length - 1) * (size - overlap) +
              (overflow > 0 ? size - overlap : 0),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.c.canvas, width: 2),
                ),
                child: AppAvatar(initials: shown[i], size: size),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.c.surfaceRaised,
                  border: Border.all(color: theme.c.canvas, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflow',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded progress bar that animates to its new value.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.tone,
  });

  final double value;
  final double height;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tone ?? theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: theme.c.border),
          LayoutBuilder(
            builder: (context, constraints) => AnimatedContainer(
              duration: AppMotion.slow,
              curve: AppMotion.easing,
              height: height,
              width: constraints.maxWidth * value.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section title with an optional trailing action.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// A square icon tile used to give list rows and stats a visual anchor.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 44,
  });

  final IconData icon;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).c.wash(tone),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: tone, size: size * 0.5),
    );
  }
}

/// Small inline spinner sized for a button's foreground.
class AppButtonSpinner extends StatelessWidget {
  const AppButtonSpinner({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: color ?? Colors.white,
      ),
    );
  }
}

/// Fades and lifts its child into place. Used to stagger list entries.
class AppFadeIn extends StatelessWidget {
  const AppFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 12,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.base + delay,
      curve: AppMotion.easing,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Confirmation dialog for destructive actions.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: AppIconTile(
        icon: destructive
            ? Icons.warning_amber_rounded
            : Icons.help_outline_rounded,
        tone: destructive ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  minimumSize: const Size(120, 46),
                )
              : FilledButton.styleFrom(minimumSize: const Size(120, 46)),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Feedback snackbar. [isError] switches the accent without changing layout.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? theme.colorScheme.error : AppColors.success,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
}
