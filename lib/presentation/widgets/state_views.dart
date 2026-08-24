import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_components.dart';
import 'app_illustrations.dart';

/// A shimmering placeholder block.
///
/// The shimmer repeats indefinitely, which is why widget tests use bounded
/// `pump` calls rather than `pumpAndSettle`.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).c;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            surfaces.border,
            surfaces.borderStrong,
            _controller.value,
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Skeleton shaped like a task or project card, so the transition to real
/// content does not shift the layout.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 2, this.showFooter = true});

  final int lines;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 44, height: 44, radius: AppRadius.md),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(height: 15),
                    const SizedBox(height: AppSpacing.sm),
                    SkeletonBox(
                      height: 12,
                      width: MediaQuery.sizeOf(context).width * 0.35,
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (var i = 0; i < lines; i++) ...[
            const SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 11, width: i.isEven ? null : 200),
          ],
          if (showFooter) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: const [
                SkeletonBox(width: 72, height: 24, radius: AppRadius.pill),
                SizedBox(width: AppSpacing.sm),
                SkeletonBox(width: 60, height: 24, radius: AppRadius.pill),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A vertical run of skeleton cards used while a list loads.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.lines = 2,
    this.itemHeight,
  });

  final int count;
  final int lines;

  /// Fixed row height for callers whose real rows are a known size.
  final double? itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => itemHeight == null
          ? SkeletonCard(lines: lines)
          : SkeletonBox(height: itemHeight!, radius: AppRadius.lg),
    );
  }
}

/// Skeleton matching the dashboard's stat grid and list previews.
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 150, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 96, radius: AppRadius.lg)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonBox(height: 96, radius: AppRadius.lg)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 96, radius: AppRadius.lg)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonBox(height: 96, radius: AppRadius.lg)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonCard(lines: 1),
          const SizedBox(height: AppSpacing.md),
          const SkeletonCard(lines: 1),
        ],
      ),
    );
  }
}

/// Designed empty state with a headline, guidance and an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.art = AppArt.tasks,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;

  /// Which vector object to show above the copy.
  final AppArt art;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: AppFadeIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIllustration(art: art, size: 88),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 220,
                  child: FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(actionLabel!),
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

/// Error state with a human message and a retry affordance. Never renders a
/// raw exception string.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.art = AppArt.error,
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;
  final AppArt art;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: AppFadeIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIllustration(art: art, size: 88),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 200,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Try again'),
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

/// Centred spinner for the few places a skeleton would not fit.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(message!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
