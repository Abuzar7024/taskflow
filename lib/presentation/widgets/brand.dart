import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// The app mark: a gradient tile with a check glyph. Drawn rather than shipped
/// as an image so it scales cleanly and follows the theme.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 52, this.showGlow = true, super.key});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: theme.surfaces.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppPalette.indigo.withValues(alpha: 0.36),
                  blurRadius: size * 0.5,
                  offset: Offset(0, size * 0.18),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * 0.56,
        color: Colors.white,
      ),
    );
  }
}

/// Brand mark plus wordmark and tagline, used on the auth screens.
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
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Abstract gradient orbs painted behind the auth screens.
///
/// Cheap to draw and theme-aware, giving the sign-in flow a sense of depth
/// without shipping image assets.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: surfaces.canvas)),
        Positioned.fill(
          child: CustomPaint(painter: _AuroraPainter(isDark: surfaces.isDark)),
        ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Opacity is lifted in dark mode so the orbs stay visible against navy.
    final alpha = isDark ? 0.30 : 0.20;

    _orb(
      canvas,
      Offset(size.width * 0.85, size.height * 0.08),
      size.width * 0.55,
      AppPalette.indigo.withValues(alpha: alpha),
    );
    _orb(
      canvas,
      Offset(size.width * 0.05, size.height * 0.30),
      size.width * 0.45,
      AppPalette.violet.withValues(alpha: alpha * 0.8),
    );
    _orb(
      canvas,
      Offset(size.width * 0.75, size.height * 0.92),
      size.width * 0.5,
      AppPalette.cyan.withValues(alpha: alpha * 0.7),
    );
  }

  void _orb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// A subtle grid drawn behind hero surfaces, adding texture at low cost.
class GridOverlay extends StatelessWidget {
  const GridOverlay({super.key, this.opacity = 0.06, this.spacing = 26});

  final double opacity;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(opacity: opacity, spacing: spacing),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.opacity, required this.spacing});

  final double opacity;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.spacing != spacing;
}

/// Circular percentage dial used for completion figures.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.strokeWidth = 7,
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
    final accent = tone ?? theme.colorScheme.primary;

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
                track: theme.surfaces.border,
                accent: accent,
                strokeWidth: strokeWidth,
              ),
            ),
            Text(
              label ?? '${(animated * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.22,
                color: theme.surfaces.textPrimary,
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
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [accent.withValues(alpha: 0.65), accent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.accent != accent;
}
