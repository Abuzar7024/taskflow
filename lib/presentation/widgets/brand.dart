import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// The app mark: a rounded tile with a check glyph. Drawn rather than shipped
/// as an image so it scales cleanly and follows the theme.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * 0.6,
        color: theme.colorScheme.onPrimary,
      ),
    );
  }
}

/// Brand mark plus wordmark, used on the auth screens.
class BrandHeader extends StatelessWidget {
  const BrandHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(),
        const SizedBox(height: AppSpacing.xl),
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
