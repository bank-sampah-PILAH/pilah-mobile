/// The font sizes of the app. Screens take a step from here (or an
/// `AppTextStyle`) instead of writing a number, so the same kind of text is
/// the same size everywhere.
abstract final class AppFontSize {
  static const double xs = 10;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 20;
  static const double display = 24;

  /// A large number such as the total cash figure.
  static const double figure = 28;

  /// A mark on the splash screen, not text to read.
  static const double jumbo = 48;
}
