import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// Up to two initials from [name] (e.g. "Ahmad Ridwan" -> "AR"), for an
/// avatar with no photo. Falls back to "NN" when [name] has no letters to
/// take.
String initialsOf(String name) {
  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'NN';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

/// A deterministic (background, text) color pair for [name]'s avatar, from a
/// fixed palette. The same name always maps to the same pair, and different
/// names are visually distinguishable — this is the one avatar-coloring
/// system every riwayat/list screen shares (setoran, pencairan, nasabah),
/// so an avatar's color means the same thing everywhere it appears (PIL-282).
(Color, Color) avatarPaletteFor(String name) {
  if (name.isEmpty) return _avatarPalette.first;
  return _avatarPalette[name.hashCode.abs() % _avatarPalette.length];
}

const List<(Color, Color)> _avatarPalette = [
  (AppColors.greenLight, AppColors.greenDark), // green
  (AppColors.avatarBlue, AppColors.avatarBlueText), // blue
  (AppColors.avatarPurple, AppColors.avatarPurpleText), // purple
  (AppColors.warningLight, AppColors.warning), // yellow
  (AppColors.avatarOrange, AppColors.avatarOrangeText), // orange
  (AppColors.avatarTeal, AppColors.avatarTealText), // teal
];
