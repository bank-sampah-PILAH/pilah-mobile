import 'dart:ui';

class AppColors {
  static const Color primary = Color(0xFF2B637B);
  static const Color secondary = Color(0xFF333333);

  static const Color black = Color(0xFF04021D);
  static const Color blue = Color(0xFF554AF0);

  static const Color grey200 = Color.fromRGBO(104, 103, 119, 0.38);
  static const Color grey100 = Color(0xFF686777);

  // Login & Shared Colors
  static const Color greenLight = Color(0xFFEAF5EC);
  // Primary green, the emerald of the logo. 6.4:1 on white, so it meets WCAG AA
  // (4.5:1) for text and for white text on it. Replaced the muted sage #5D8E6C
  // (3.78:1) and the copies of this emerald that lived in a dozen screens.
  static const Color greenDark = Color(0xFF006D44);
  static const Color cardOffWhite = Color(0xFFFAFAFA);

  // Neutral greys. These replaced ten near-identical greys copied into screens.
  /// Page and card background.
  static const Color surface = Color(0xFFF9FAFB);

  /// Chips, inputs and badges.
  static const Color fill = Color(0xFFF3F4F6);

  /// Dividers and outlines.
  static const Color border = Color(0xFFE5E7EB);

  /// Strong secondary text (10:1 on white). Muted text is [grey100].
  static const Color inkSoft = Color(0xFF374151);

  /// Fills behind white initials on the profile header avatar. Each is at least
  /// 4.5:1 against white (checked in test/design/contrast_test.dart).
  static const List<Color> avatarFills = [
    greenDark,
    Color(0xFF7C3AED),
    warning,
    Color(0xFF0F766E),
    Color(0xFF9A3412),
  ];

  // Danger red and its tint. #C62828 is 5.6:1 on white and 5.1:1 on the tint
  // (WCAG AA); it replaced #DC2626, which fell to 4.4:1 on the tint.
  static const Color danger = Color(0xFFC62828);
  static const Color dangerLight = Color(0xFFFEF2F2);

  // Warning amber and its tint. #976200 is 5.2:1 on white and 4.6:1 on the
  // tint (WCAG AA); it replaced thirteen ambers, five of which failed AA as
  // text.
  static const Color warning = Color(0xFF976200);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Dashboard Colors
  static const Color statOrangeLight = Color(0xFFFFF5E6);
  static const Color statOrange = Color(0xFFEBA658);
  static const Color statPurpleLight = Color(0xFFF4EDFA);
  static const Color statPurple = Color(0xFFA583D9);

  // List Avatars
  static const Color avatarYellow = Color(0xFFFFF8D6);
  static const Color avatarYellowText = Color(0xFFD4A017);
}
