import 'package:flutter/widgets.dart';

/// Moderate corner radii — rounded enough to feel current, restrained enough
/// to read as an application control rather than a toy.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
