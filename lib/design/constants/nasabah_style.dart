import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// Shared visual tokens for the nasabah screens.
abstract final class NasabahStyle {
  static const emerald = AppColors.greenDark;
  static const ink = AppColors.black;
  static const muted = AppColors.grey100;
  static const line = AppColors.grey200;
  static const background = Colors.white;
  static const emeraldLight = AppColors.greenLight;
  static const emeraldDark = AppColors.greenDark;
  static const maxWidth = 600.0;
  // Shared caption color for the small caps labels above a card value
  // (e.g. "EMAIL", "NOMOR HP"). Kept as one token so every card agrees.
  static const labelMuted = Color(0xFF64748B);

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double height = 1.45,
    bool tabularFigures = false,
  }) =>
      GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          fontFeatures:
              tabularFigures ? const [FontFeature.tabularFigures()] : null,
        ),
      );
}
