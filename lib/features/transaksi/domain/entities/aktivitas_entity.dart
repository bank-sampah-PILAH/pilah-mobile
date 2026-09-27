import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import 'transaksi_entity.dart';

enum ActivitasTipe { setoran, pencairan }

/// A single row in the unified Riwayat Aktivitas feed (PIL-282): either a
/// setoran or a pencairan, normalized to the shape `ActivityItem` renders,
/// while keeping the original typed record so a tap can still open that
/// type's own detail sheet.
class ActivitasEntity {
  final ActivitasTipe tipe;

  /// Null only for a legacy record with no timestamp at all; sorts last.
  final DateTime? tanggal;

  final String avatarText;
  final Color avatarColor;
  final Color avatarTextColor;
  final String title;
  final List<String> subtitleLines;
  final String amount;
  final Color? amountColor;
  final List<String> trailingCaptions;
  final String? badge;

  /// The searchable name (nasabah), independent of how [title] is composed.
  final String searchTerm;

  final TransaksiEntity? transaksi;
  final Pencairan? pencairan;

  const ActivitasEntity({
    required this.tipe,
    required this.tanggal,
    required this.avatarText,
    required this.avatarColor,
    required this.avatarTextColor,
    required this.title,
    required this.subtitleLines,
    required this.amount,
    this.amountColor,
    this.trailingCaptions = const [],
    this.badge,
    required this.searchTerm,
    this.transaksi,
    this.pencairan,
  });

  factory ActivitasEntity.fromTransaksi(TransaksiEntity t) {
    return ActivitasEntity(
      tipe: ActivitasTipe.setoran,
      tanggal: t.tanggal,
      avatarText: t.initials,
      avatarColor: t.avatarColor,
      avatarTextColor: t.textColor,
      title: t.name,
      subtitleLines: [t.subtitle],
      amount: t.amount,
      trailingCaptions: [if (t.time != null) t.time!],
      searchTerm: t.name,
      transaksi: t,
    );
  }

  factory ActivitasEntity.fromPencairan(Pencairan p) {
    // Same hash-based palette setoran avatars use, keyed by nasabah name —
    // one avatar-coloring system across the whole merged feed, not two
    // independently-colored ones (PIL-282).
    final palette = avatarPaletteFor(p.nasabahNama);
    return ActivitasEntity(
      tipe: ActivitasTipe.pencairan,
      tanggal: p.tanggal,
      avatarText: initialsOf(p.nasabahNama),
      avatarColor: palette.$1,
      avatarTextColor: palette.$2,
      title: p.nasabahNama,
      // One line only, like setoran's subtitle — no separate keterangan line
      // and no Diperbarui badge, so an edited pencairan reads the same as
      // any other row in the merged feed (still visible in its own detail
      // sheet, just not singled out here).
      subtitleLines: [p.metode.label],
      amount: '-Rp ${_rupiah(p.nominal)}',
      // No amountColor override: falls through to ActivityItem's own
      // default (AppColors.greenDark), the same accent setoran rows use.
      trailingCaptions: [if (p.tanggal != null) _time(p.tanggal!)],
      searchTerm: p.nasabahNama,
      pencairan: p,
    );
  }

  static String _time(DateTime tanggal) =>
      '${tanggal.hour.toString().padLeft(2, '0')}:${tanggal.minute.toString().padLeft(2, '0')}';

  static String _rupiah(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
