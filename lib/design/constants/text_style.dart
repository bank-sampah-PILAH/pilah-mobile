import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

class AppTextStyle {
  static TextStyle small = GoogleFonts.poppins(
      textStyle: const TextStyle(
    height: 1.5,
    color: AppColors.black,
    fontSize: AppFontSize.sm,
  ));

  static TextStyle extraSmall = GoogleFonts.poppins(
      textStyle: const TextStyle(
    height: 1.5,
    color: AppColors.grey100,
    fontSize: AppFontSize.xs,
  ));

  static TextStyle title1 = GoogleFonts.poppins(
      textStyle: const TextStyle(
    height: 1.5,
    color: AppColors.black,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.xl,
  ));

  static TextStyle headline1 = GoogleFonts.poppins(
      textStyle: const TextStyle(
    height: 1.5,
    color: AppColors.black,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.display,
  ));

  static TextStyle regularSemiBold = GoogleFonts.poppins(
      textStyle: const TextStyle(
          height: 1.5, fontWeight: FontWeight.w500, color: Colors.white));

  static TextStyle headline3 = GoogleFonts.poppins(
      textStyle: const TextStyle(
    height: 1.5,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.lg,
  ));

  static TextStyle appBar = GoogleFonts.poppins(
      textStyle: const TextStyle(
          height: 1.5,
          fontWeight: FontWeight.w600,
          fontSize: AppFontSize.xl,
          color: AppColors.black));
}
