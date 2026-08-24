import 'package:flutter/material.dart';

/// The blue + cream palette.
///
/// Flat colours only — the product deliberately uses no gradients. Light and
/// dark are specified independently rather than one being an inversion of the
/// other, so contrast and hierarchy stay intentional in both.
abstract final class AppColors {
  // Brand blues
  static const deepBlue = Color(0xFF173B63);
  static const primaryBlue = Color(0xFF2563A6);
  static const mediumBlue = Color(0xFF3D7CBF);
  static const softBlue = Color(0xFFE8F0F7);

  // Cream neutrals
  static const cream = Color(0xFFF8F5ED);
  static const creamRaised = Color(0xFFFDFBF6);
  static const creamSunken = Color(0xFFF2EEE3);

  // Text
  static const darkText = Color(0xFF17202A);
  static const mutedText = Color(0xFF687582);

  // Semantic
  static const success = Color(0xFF3E8E68);
  static const warning = Color(0xFFC68A28);
  static const error = Color(0xFFC75C5C);

  // Dark theme — navy, designed rather than inverted.
  static const navyBase = Color(0xFF0F1720);
  static const navySurface = Color(0xFF16202B);
  static const navyRaised = Color(0xFF1D2936);
  static const navyBorder = Color(0xFF2A3846);
  static const navySoft = Color(0xFF1B2A3A);

  static const darkPrimary = Color(0xFF5B9BD5);
  static const darkText_ = Color(0xFFE8EDF2);
  static const darkMuted = Color(0xFF93A3B4);

  static const darkSuccess = Color(0xFF5AA987);
  static const darkWarning = Color(0xFFD9A44E);
  static const darkError = Color(0xFFD97B7B);
}

/// Surface roles resolved per theme, reached via `Theme.of(context).c`.
///
/// Screens read these instead of referencing [AppColors] directly, so a widget
/// never needs to ask which brightness is active.
@immutable
class AppColorRoles extends ThemeExtension<AppColorRoles> {
  const AppColorRoles({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceAccent,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.shadow,
  });

  factory AppColorRoles.light() => const AppColorRoles(
    canvas: AppColors.cream,
    surface: AppColors.creamRaised,
    surfaceRaised: Colors.white,
    surfaceAccent: AppColors.softBlue,
    border: Color(0xFFE4DFD2),
    borderStrong: Color(0xFFCFC8B6),
    text: AppColors.darkText,
    textMuted: AppColors.mutedText,
    primary: AppColors.primaryBlue,
    onPrimary: Colors.white,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    shadow: Color(0x0F17202A),
  );

  factory AppColorRoles.dark() => const AppColorRoles(
    canvas: AppColors.navyBase,
    surface: AppColors.navySurface,
    surfaceRaised: AppColors.navyRaised,
    surfaceAccent: AppColors.navySoft,
    border: AppColors.navyBorder,
    borderStrong: Color(0xFF3A4A5C),
    text: AppColors.darkText_,
    textMuted: AppColors.darkMuted,
    primary: AppColors.darkPrimary,
    onPrimary: Color(0xFF0B121A),
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    error: AppColors.darkError,
    shadow: Color(0x33000000),
  );

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;

  /// Soft blue panel used for highlights and selected states.
  final Color surfaceAccent;

  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color primary;
  final Color onPrimary;
  final Color success;
  final Color warning;
  final Color error;
  final Color shadow;

  bool get isDark => canvas == AppColors.navyBase;

  /// A very soft shadow, used only where a surface must lift off the page.
  List<BoxShadow> get softShadow => [
    BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 2)),
  ];

  /// Low-opacity wash of [accent], for chips and status pills.
  Color wash(Color accent) => accent.withValues(alpha: isDark ? 0.18 : 0.10);

  @override
  AppColorRoles copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceAccent,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? success,
    Color? warning,
    Color? error,
    Color? shadow,
  }) {
    return AppColorRoles(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceAccent: surfaceAccent ?? this.surfaceAccent,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColorRoles lerp(AppColorRoles? other, double t) {
    if (other == null) return this;
    return AppColorRoles(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceAccent: Color.lerp(surfaceAccent, other.surfaceAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppColorAccess on ThemeData {
  /// The palette for the active theme.
  AppColorRoles get c => extension<AppColorRoles>()!;
}
