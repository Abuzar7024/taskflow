import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the light and dark themes.
///
/// Both come from one builder parameterised by the palette, so component
/// styling is written once while the two palettes stay independently designed.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColorRoles.light(), Brightness.light);
  static ThemeData dark() => _build(AppColorRoles.dark(), Brightness.dark);

  static ThemeData _build(AppColorRoles c, Brightness brightness) {
    final text = AppTypography.build(c);
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.surfaceAccent,
      onPrimaryContainer: isDark ? c.text : AppColors.deepBlue,
      secondary: isDark ? AppColors.mediumBlue : AppColors.deepBlue,
      onSecondary: Colors.white,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      error: c.error,
      onError: Colors.white,
      outline: c.borderStrong,
      outlineVariant: c.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [c],
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: c.text, size: 22),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: c.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? c.surfaceRaised : Colors.white,
        // Compact fields: a form control, not a hero element.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        isDense: true,
        hintStyle: text.bodyMedium?.copyWith(
          color: c.textMuted.withValues(alpha: 0.75),
        ),
        labelStyle: text.bodyMedium,
        floatingLabelStyle: text.labelMedium?.copyWith(color: c.primary),
        prefixIconColor: c.textMuted,
        suffixIconColor: c.textMuted,
        border: _border(c.border),
        enabledBorder: _border(c.border),
        focusedBorder: _border(c.primary, width: 1.5),
        errorBorder: _border(c.error),
        focusedErrorBorder: _border(c.error, width: 1.5),
        errorStyle: text.bodySmall?.copyWith(color: c.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.field),
          textStyle: text.labelLarge,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.45),
          disabledForegroundColor: c.onPrimary.withValues(alpha: 0.8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          backgroundColor: isDark ? Colors.transparent : Colors.white,
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: BorderSide(color: c.primary.withValues(alpha: 0.5)),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.field),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.textMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceAccent,
        side: BorderSide(color: c.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.surfaceAccent,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.chip,
        ),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.textMuted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.surfaceAccent,
        selectedIconTheme: IconThemeData(color: c.primary, size: 22),
        unselectedIconTheme: IconThemeData(color: c.textMuted, size: 22),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: c.primary),
        unselectedLabelTextStyle: text.labelMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
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
        backgroundColor: isDark ? c.surfaceRaised : AppColors.deepBlue,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: isDark ? c.text : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: c.textMuted,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.border,
        linearMinHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : null,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? c.surfaceRaised : AppColors.deepBlue,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: text.bodySmall?.copyWith(
          color: isDark ? c.text : Colors.white,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.field,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Motion durations. Deliberately short — animation supports the interaction
/// rather than decorating it.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);

  static const easing = Curves.easeOutCubic;
}
