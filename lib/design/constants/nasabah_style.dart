import 'package:flutter/material.dart';

/// Shared visual tokens for the nasabah screens.
abstract final class NasabahStyle {
  static const emerald = Color(0xFF059669);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const background = Color(0xFFF8FAFC);
  static const emeraldLight = Color(0xFFD1FAE5);
  static const emeraldDark = Color(0xFF047857);
  static const maxWidth = 600.0;

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double height = 1.45,
    bool tabularFigures = false,
  }) =>
      TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        fontFeatures:
            tabularFigures ? const [FontFeature.tabularFigures()] : null,
      );
}
