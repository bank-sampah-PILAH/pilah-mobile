/// The corner radii of the app. Use these instead of a number in a screen, so
/// two cards or two inputs never differ by a few pixels.
class AppRadius {
  const AppRadius._();

  /// Chips and small tiles.
  static const double sm = 8;

  /// Inputs and buttons.
  static const double md = 12;

  /// Cards and dialogs.
  static const double lg = 16;

  /// Bottom sheets and hero cards.
  static const double xl = 24;
}
