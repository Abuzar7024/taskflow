import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The type scale.
///
/// Hierarchy comes from size and colour rather than from making everything
/// bold; body copy sits at a comfortable reading weight throughout.
abstract final class AppTypography {
  static TextTheme build(AppColorRoles c) {
    return TextTheme(
      // Dashboard statistics.
      displaySmall: TextStyle(
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: c.text,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: c.text,
      ),
      // Page titles.
      headlineSmall: TextStyle(
        fontSize: 21,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: c.text,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: c.text,
      ),
      // Section headings.
      titleMedium: TextStyle(
        fontSize: 15.5,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: c.text,
      ),
      titleSmall: TextStyle(
        fontSize: 14.5,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: c.text,
      ),
      bodyLarge: TextStyle(fontSize: 15.5, height: 1.5, color: c.text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: c.textMuted),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.45, color: c.textMuted),
      labelLarge: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: c.textMuted,
      ),
      // Metadata and overlines.
      labelSmall: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: c.textMuted,
      ),
    );
  }
}
