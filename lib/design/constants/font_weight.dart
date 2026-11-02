import 'package:flutter/painting.dart';

/// The font weights of the app: the four faces of the bundled Poppins. Screens
/// take a step from here (or an `AppTextStyle`) instead of writing a
/// `FontWeight`, so the same kind of text is the same weight everywhere.
abstract final class AppFontWeight {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}
