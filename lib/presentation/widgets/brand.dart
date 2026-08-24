import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// The app mark: a solid blue tile with a check glyph. Drawn rather than
/// shipped as an image so it scales cleanly and follows the theme.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).c.primary,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(Icons.check_rounded, size: size * 0.56, color: Colors.white),
    );
  }
}

/// Brand lockup and page intro used on the auth screens.
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
        Row(
          children: [
            const BrandMark(),
            const SizedBox(width: AppSpacing.md),
            Text(
              'TaskFlow',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Circular percentage dial used for completion figures.
///
/// Flat single-colour arc — no gradient, no glow.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 56,
    this.strokeWidth = 5,
    this.tone,
    this.label,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color? tone;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tone ?? theme.c.primary;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: AppMotion.slow,
        curve: AppMotion.easing,
        builder: (context, animated, _) => Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                value: animated,
                track: theme.c.border,
                accent: accent,
                strokeWidth: strokeWidth,
              ),
            ),
            Text(
              label ?? '${(animated * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: size * 0.21,
                color: theme.c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.track,
    required this.accent,
    required this.strokeWidth,
  });

  final double value;
  final Color track;
  final Color accent;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = track,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.accent != accent || old.track != track;
}
