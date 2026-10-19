import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import 'jadwal_calendar.dart';

/// Ringkasan jadwal mendatang di bawah kalender web: beberapa tanggal berjadwal
/// terdekat, lalu satu baris per bulan berikutnya dengan jumlah harinya.
/// Mengisi kolom kalender dan menjadi jalan pintas ke hari atau bulan yang akan
/// datang; isi jadwalnya tetap di agenda.
///
/// [upcomingDates] memuat tanggal berjadwal dari hari ini ke depan, terlepas
/// dari bulan yang tampil di kalender. Yang dihitung adalah hari berjadwal,
/// bukan jumlah jadwal: itu yang diketahui dari titik-titik kalender.
class JadwalUpcomingDates extends StatelessWidget {
  const JadwalUpcomingDates({
    super.key,
    required this.upcomingDates,
    required this.today,
    required this.selectedDate,
    required this.onSelect,
    this.limit = 3,
  });

  final Set<DateTime> upcomingDates;
  final DateTime today;
  final DateTime selectedDate;

  /// Dipanggil dengan tanggal yang dipilih; untuk sebuah bulan, hari
  /// berjadwal pertamanya.
  final ValueChanged<DateTime> onSelect;

  /// Banyak tanggal terdekat yang ditampilkan.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final start = DateUtils.dateOnly(today);
    final upcoming = (upcomingDates.map(DateUtils.dateOnly).toSet()
          ..removeWhere((d) => d.isBefore(start)))
        .toList()
      ..sort();
    final months = _laterMonths(upcoming, start);
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
          const _Heading('Berikutnya'),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'Belum ada jadwal dalam 3 bulan ke depan.',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
            )
          else
            for (final date in upcoming.take(limit))
              _Row(
                label: formatJadwalDayHeading(date, today: start),
                selected: DateUtils.isSameDay(date, selectedDate),
                onTap: () => onSelect(date),
              ),
          if (months.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            const _Heading('Bulan berikutnya'),
            for (final month in months)
              _Row(
                label: formatJadwalMonth(month.first),
                trailing: '${month.length} hari berjadwal',
                onTap: () => onSelect(month.first),
              ),
          ],
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

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Text(
          text,
          style: AppTextStyle.small.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.onTap,
    this.trailing,
    this.selected = false,
  });

  final String label;
  final String? trailing;
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
            if (trailing != null) ...[
              Text(
                trailing!,
                style:
                    AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            const Icon(Icons.chevron_right, size: 18, color: AppColors.grey100),
          ],
        ),
      ),
    );
  }
}
