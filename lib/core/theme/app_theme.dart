import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';

/// Builds the light and dark themes from the design tokens.
///
/// Component themes are configured here so screens never restyle a button or
/// an input inline.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surfaces = isDark ? AppSurfaces.dark() : AppSurfaces.light();

    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.indigo,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppPalette.indigoBright : AppPalette.indigo,
          secondary: AppPalette.violet,
          tertiary: AppPalette.cyan,
          error: AppPalette.coral,
          surface: surfaces.canvas,
          onSurface: surfaces.textPrimary,
          onSurfaceVariant: surfaces.textSecondary,
          outlineVariant: surfaces.border,
        );

    final text = _textTheme(surfaces);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaces.canvas,
      canvasColor: surfaces.canvas,
      splashFactory: InkSparkle.splashFactory,
      extensions: [surfaces],
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaces.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: surfaces.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surfaces.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: surfaces.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaces.cardElevated : surfaces.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: surfaces.textMuted),
        labelStyle: text.bodyMedium?.copyWith(color: surfaces.textSecondary),
        floatingLabelStyle: text.labelLarge?.copyWith(color: scheme.primary),
        prefixIconColor: surfaces.textMuted,
        suffixIconColor: surfaces.textMuted,
        border: _border(surfaces.border),
        enabledBorder: _border(surfaces.border),
        focusedBorder: _border(scheme.primary, width: 1.8),
        errorBorder: _border(scheme.error),
        focusedErrorBorder: _border(scheme.error, width: 1.8),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.field),
          textStyle: text.labelLarge,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: surfaces.textPrimary,
          side: BorderSide(color: surfaces.borderStrong),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.field),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: surfaces.textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaces.cardElevated,
        side: BorderSide(color: surfaces.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: surfaces.border,
        space: 1,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaces.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.chip,
        ),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : surfaces.textMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : surfaces.textMuted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaces.card,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 24),
        unselectedIconTheme: IconThemeData(color: surfaces.textMuted, size: 24),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(
          color: surfaces.textMuted,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaces.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        showDragHandle: true,
        dragHandleColor: surfaces.borderStrong,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaces.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppPalette.navy600 : const Color(0xFF1E293B),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: surfaces.textSecondary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: surfaces.border,
        linearMinHeight: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppPalette.navy600 : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: text.bodySmall?.copyWith(color: Colors.white),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.field,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// A deliberate type scale: large display numbers for statistics, strong
  /// titles, and muted metadata, so hierarchy comes from the scale rather
  /// than from making everything bold.
  static TextTheme _textTheme(AppSurfaces surfaces) {
    final primary = surfaces.textPrimary;
    final secondary = surfaces.textSecondary;
    final muted = surfaces.textMuted;

    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: primary),
      bodyMedium: TextStyle(fontSize: 14.5, height: 1.5, color: secondary),
      bodySmall: TextStyle(fontSize: 13, height: 1.45, color: muted),
      labelLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: muted,
      ),
    );
  }
}
