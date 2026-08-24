import 'package:flutter/material.dart';

/// The single source of truth for the visual language.
///
/// Every colour, radius, shadow and gradient in the app resolves from here, so
/// the design stays consistent and can be retuned in one place.

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double huge = 40;

  /// Horizontal page padding, widened on larger surfaces.
  static double page(double width) => width >= 900 ? xxl : lg;
}

abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

/// The futuristic SaaS palette. Hues stay constant across themes so a status
/// colour is always recognisable; only surfaces and text invert.
abstract final class AppPalette {
  // Brand
  static const indigo = Color(0xFF4F46E5);
  static const indigoBright = Color(0xFF6366F1);
  static const violet = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF06B6D4);
  static const electric = Color(0xFF3B82F6);

  // Semantic
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const coral = Color(0xFFF43F5E);
  static const slate = Color(0xFF64748B);

  // Dark surfaces — deep navy rather than neutral black.
  static const navy900 = Color(0xFF0B1020);
  static const navy800 = Color(0xFF121933);
  static const navy700 = Color(0xFF1A2340);
  static const navy600 = Color(0xFF243056);

  // Light surfaces — cool greys, never pure white.
  static const mist50 = Color(0xFFF7F8FC);
  static const mist100 = Color(0xFFEFF2F9);
  static const white = Color(0xFFFFFFFF);
}

/// Surface and accent colours resolved for the active brightness.
///
/// Read through `Theme.of(context).surfaces` rather than referencing
/// [AppPalette] directly in a widget.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.canvas,
    required this.card,
    required this.cardElevated,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.shadow,
    required this.brandGradient,
    required this.heroGradient,
    required this.isDark,
  });

  factory AppSurfaces.light() => const AppSurfaces(
    canvas: AppPalette.mist50,
    card: AppPalette.white,
    cardElevated: AppPalette.white,
    border: Color(0xFFE3E8F2),
    borderStrong: Color(0xFFCBD5E6),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    shadow: Color(0x14101828),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppPalette.indigo, AppPalette.violet],
    ),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF2563EB)],
    ),
    isDark: false,
  );

  factory AppSurfaces.dark() => const AppSurfaces(
    canvas: AppPalette.navy900,
    card: AppPalette.navy800,
    cardElevated: AppPalette.navy700,
    border: Color(0xFF243056),
    borderStrong: Color(0xFF33406B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFFB6C2D9),
    textMuted: Color(0xFF7C8AA8),
    shadow: Color(0x40000000),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppPalette.indigoBright, AppPalette.violet],
    ),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3730A3), Color(0xFF5B21B6), Color(0xFF1D4ED8)],
    ),
    isDark: true,
  );

  final Color canvas;
  final Color card;
  final Color cardElevated;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color shadow;
  final LinearGradient brandGradient;
  final LinearGradient heroGradient;
  final bool isDark;

  /// Soft ambient shadow used by cards. Kept low-opacity so surfaces read as
  /// layered rather than heavy.
  List<BoxShadow> get cardShadow => [
    BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 8)),
  ];

  List<BoxShadow> get raisedShadow => [
    BoxShadow(color: shadow, blurRadius: 36, offset: const Offset(0, 14)),
  ];

  /// Tint used behind an accent colour for chips and icon tiles.
  Color tint(Color accent) =>
      accent.withValues(alpha: isDark ? 0.20 : 0.10);

  @override
  AppSurfaces copyWith({
    Color? canvas,
    Color? card,
    Color? cardElevated,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? shadow,
    LinearGradient? brandGradient,
    LinearGradient? heroGradient,
    bool? isDark,
  }) {
    return AppSurfaces(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      shadow: shadow ?? this.shadow,
      brandGradient: brandGradient ?? this.brandGradient,
      heroGradient: heroGradient ?? this.heroGradient,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppSurfaces lerp(AppSurfaces? other, double t) {
    if (other == null) return this;
    return AppSurfaces(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      brandGradient: t < 0.5 ? brandGradient : other.brandGradient,
      heroGradient: t < 0.5 ? heroGradient : other.heroGradient,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppThemeAccess on ThemeData {
  AppSurfaces get surfaces => extension<AppSurfaces>()!;
}

/// Durations for the app's micro-interactions. Kept short so the UI feels
/// responsive rather than animated for its own sake.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 380);

  static const easing = Curves.easeOutCubic;
  static const emphasis = Curves.easeOutBack;
}
