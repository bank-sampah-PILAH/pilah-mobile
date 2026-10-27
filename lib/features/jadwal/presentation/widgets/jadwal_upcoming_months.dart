import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import 'jadwal_calendar.dart';

/// Ringkasan "Berikutnya" di bawah kalender web: satu baris per bulan dengan
/// jumlah hari berjadwal yang belum lewat, mulai dari bulan ini (hanya hari ini
/// dan sesudahnya). Mengetuk satu baris membuka jadwal bulan itu yang belum
/// lewat: hari berjadwal pertamanya sampai akhir bulan.
///
/// [upcomingDates] memuat tanggal berjadwal dari hari ini ke depan, terlepas
/// dari bulan yang tampil di kalender. Yang dihitung adalah hari berjadwal,
/// bukan jumlah jadwal: itu yang diketahui dari titik-titik kalender.
class JadwalUpcomingMonths extends StatelessWidget {
  const JadwalUpcomingMonths({
    super.key,
    required this.upcomingDates,
    required this.today,
    required this.selectedDate,
    required this.onSelect,
  });

  final Set<DateTime> upcomingDates;
  final DateTime today;

  /// Bulan yang memuat tanggal ini diberi warna.
  final DateTime selectedDate;

  /// Dipanggil dengan hari berjadwal pertama bulan yang diketuk yang belum
  /// lewat.
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final start = DateUtils.dateOnly(today);
    final months = _monthsFrom(
      (upcomingDates.map(DateUtils.dateOnly).toSet()
            ..removeWhere((d) => d.isBefore(start)))
          .toList()
        ..sort(),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Text(
              'Berikutnya',
              style: AppTextStyle.small.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (months.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'Belum ada jadwal mendatang dalam 3 bulan ke depan.',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
            )
          else
            for (final month in months)
              _MonthRow(
                label: _sameMonth(month.first, start)
                    ? 'Bulan ini'
                    : formatJadwalMonth(month.first),
                days: month.length,
                selected: _sameMonth(month.first, selectedDate),
                onTap: () => onSelect(month.first),
              ),
        ],
      ),
    );
  }

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Hari berjadwal per bulan, dari [start] ke depan, berurutan.
  static List<List<DateTime>> _monthsFrom(List<DateTime> sorted) {
    final months = <List<DateTime>>[];
    for (final date in sorted) {
      if (months.isNotEmpty && _sameMonth(months.last.first, date)) {
        months.last.add(date);
      } else {
        months.add([date]);
      }
    }
    return months;
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.label,
    required this.days,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int days;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      hoverColor: AppColors.greenLight.withValues(alpha: 0.45),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenLight : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.small.copyWith(
                  color: selected ? AppColors.greenDark : AppColors.black,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$days hari berjadwal',
              style: AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.grey100),
          ],
        ),
      ),
    );
  }
}
