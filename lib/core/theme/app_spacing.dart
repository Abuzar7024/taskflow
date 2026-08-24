/// An 8px spacing scale. Every gap and padding in the app is one of these.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  /// Horizontal page margin, widened on larger surfaces.
  static double page(double width) => width >= 900 ? xxl : lg;
}
