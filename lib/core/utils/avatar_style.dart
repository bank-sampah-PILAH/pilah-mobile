import 'package:flutter/material.dart';

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
  (Color(0xFFEAF5EC), Color(0xFF2F6B45)), // green
  (Color(0xFFDBEAFE), Color(0xFF1E40AF)), // blue
  (Color(0xFFF3E8FF), Color(0xFF6B21A8)), // purple
  (Color(0xFFFFF8D6), Color(0xFFD4A017)), // yellow
  (Color(0xFFFFEDD5), Color(0xFF9A3412)), // orange
  (Color(0xFFCCFBF1), Color(0xFF0F766E)), // teal
];
