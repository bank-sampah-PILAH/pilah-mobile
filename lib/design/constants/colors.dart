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

  // Danger red and its tint. #C62828 is 5.6:1 on white and 5.1:1 on the tint
  // (WCAG AA); it replaced #DC2626, which fell to 4.4:1 on the tint.
  static const Color danger = Color(0xFFC62828);
  static const Color dangerLight = Color(0xFFFEF2F2);

  // Dashboard Colors
  static const Color statOrangeLight = Color(0xFFFFF5E6);
  static const Color statOrange = Color(0xFFEBA658);
  static const Color statPurpleLight = Color(0xFFF4EDFA);
  static const Color statPurple = Color(0xFFA583D9);

  // List Avatars
  static const Color avatarYellow = Color(0xFFFFF8D6);
  static const Color avatarYellowText = Color(0xFFD4A017);
}
