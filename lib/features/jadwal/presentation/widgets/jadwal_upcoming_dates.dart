import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import 'jadwal_calendar.dart';

/// Tanggal berjadwal berikutnya, di bawah kalender web: mengisi kolom
/// kalender dan menjadi jalan pintas ke hari yang akan datang. Hanya tanggal
/// yang kalendernya sudah punya titik; isi jadwalnya tetap di agenda.
class JadwalUpcomingDates extends StatelessWidget {
  const JadwalUpcomingDates({
    super.key,
    required this.scheduledDates,
    required this.today,
    required this.selectedDate,
    required this.onSelect,
    this.limit = 4,
  });

  final Set<DateTime> scheduledDates;
  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final start = DateUtils.dateOnly(today);
    final upcoming = (scheduledDates.map(DateUtils.dateOnly).toSet()
          ..removeWhere((d) => d.isBefore(start)))
        .toList()
      ..sort();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'Belum ada jadwal mendatang.',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
            )
          else
            for (final date in upcoming.take(limit))
              _DateRow(
                label: formatJadwalDayHeading(date, today: start),
                selected: DateUtils.isSameDay(date, selectedDate),
                onTap: () => onSelect(date),
              ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
            const Icon(Icons.chevron_right, size: 18, color: AppColors.grey100),
          ],
        ),
      ),
    );
  }
}
