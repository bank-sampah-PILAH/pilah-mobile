/// The corner radii of the app. Use these instead of a number in a screen, so
/// two cards or two inputs never differ by a few pixels.
abstract final class AppRadius {
  /// Thin marks: progress bars, indicators, legend swatches and chart bars.
  static const double xs = 4;

  /// Chips and small tiles.
  static const double sm = 8;

  /// Inputs and buttons.
  static const double md = 12;

  /// Cards and dialogs.
  static const double lg = 16;

  /// Bottom sheets and hero cards.
  static const double xl = 24;

  /// Fully rounded ends (status badges and pill chips), whatever the height.
  static const double pill = 999;
}
