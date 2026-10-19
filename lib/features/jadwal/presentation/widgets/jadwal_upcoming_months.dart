import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import 'jadwal_calendar.dart';

/// Ringkasan bulan-bulan berikutnya di bawah kalender web: satu baris per
/// bulan dengan jumlah hari berjadwalnya. Bulan ini tidak ada di sini karena
/// agenda di sebelahnya sudah memuat sisa bulan; baris ini menjadi jalan pintas
/// ke bulan yang akan datang.
///
/// [upcomingDates] memuat tanggal berjadwal dari hari ini ke depan, terlepas
/// dari bulan yang tampil di kalender. Yang dihitung adalah hari berjadwal,
/// bukan jumlah jadwal: itu yang diketahui dari titik-titik kalender.
class JadwalUpcomingMonths extends StatelessWidget {
  const JadwalUpcomingMonths({
    super.key,
    required this.upcomingDates,
    required this.today,
    required this.onSelect,
  });

  final Set<DateTime> upcomingDates;
  final DateTime today;

  /// Dipanggil dengan hari berjadwal pertama bulan yang diketuk.
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final start = DateUtils.dateOnly(today);
    final months = _laterMonths(
      (upcomingDates.map(DateUtils.dateOnly).toSet()
            ..removeWhere((d) => d.isBefore(start)))
          .toList()
        ..sort(),
      start,
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
              'Bulan berikutnya',
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
                'Belum ada jadwal dalam 3 bulan ke depan.',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
            )
          else
            for (final month in months)
              _MonthRow(
                label: formatJadwalMonth(month.first),
                days: month.length,
                onTap: () => onSelect(month.first),
              ),
        ],
      ),
    );
  }

  /// Hari berjadwal per bulan setelah bulan [start], berurutan.
  static List<List<DateTime>> _laterMonths(
    List<DateTime> sorted,
    DateTime start,
  ) {
    final months = <List<DateTime>>[];
    for (final date in sorted) {
      final later = date.year > start.year ||
          (date.year == start.year && date.month > start.month);
      if (!later) continue;
      if (months.isNotEmpty &&
          months.last.first.year == date.year &&
          months.last.first.month == date.month) {
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
    required this.onTap,
  });

  final String label;
  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      hoverColor: AppColors.greenLight.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.small.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
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
