import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_calendar_range_picker.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';

const _indonesianMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _reportDateIndonesian(DateTime date) =>
    '${date.day} ${_indonesianMonths[date.month - 1]} ${date.year}';

String reportDateRangeCaption(DashboardReportRange range) =>
    'Menampilkan ${_reportDateIndonesian(range.start)} sampai '
    '${_reportDateIndonesian(range.end)}';

String reportCategoryWeightSubtitle(DashboardReportRange range) {
  if (DateUtils.isSameDay(range.start, range.end)) {
    return 'Berat per kategori, ${_reportDateIndonesian(range.start)}';
  }
  if (range.start.year == range.end.year &&
      range.start.month == range.end.month) {
    return 'Berat per kategori, ${range.start.day} sampai ${range.end.day} '
        '${_indonesianMonths[range.end.month - 1]} ${range.end.year}';
  }
  return 'Berat per kategori, ${_reportDateIndonesian(range.start)} sampai '
      '${_reportDateIndonesian(range.end)}';
}

class DashboardReportRangeFilter extends StatelessWidget {
  final DashboardReportRange range;
  final ValueChanged<DashboardReportRange> onChanged;

  const DashboardReportRangeFilter({
    super.key,
    required this.range,
    required this.onChanged,
  });

  DashboardReportRange _preset(int days) {
    final today = DateUtils.dateOnly(DateTime.now());
    return DashboardReportRange(
      start: DateTime(today.year, today.month, today.day - days + 1),
      end: today,
    );
  }

  bool _isSelected(DashboardReportRange preset) =>
      DateUtils.isSameDay(range.start, preset.start) &&
      DateUtils.isSameDay(range.end, preset.end);

  @override
  Widget build(BuildContext context) {
    final controller = MenuController();
    final today = DateUtils.dateOnly(DateTime.now());
    final lastDate = range.end.isAfter(today) ? range.end : today;
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      side: BorderSide(color: AppColors.greenDark.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: AppTextStyle.small.copyWith(fontWeight: FontWeight.w600),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final days in [1, 7, 30])
            Semantics(
              selected: _isSelected(_preset(days)),
              child: OutlinedButton(
                style: style.copyWith(
                  foregroundColor: WidgetStatePropertyAll(
                      _isSelected(_preset(days))
                          ? Colors.white
                          : AppColors.grey100),
                  backgroundColor: WidgetStatePropertyAll(
                      _isSelected(_preset(days))
                          ? AppColors.greenDark
                          : Colors.white),
                ),
                onPressed: () => onChanged(_preset(days)),
                child: Text(days == 1 ? 'Hari ini' : '$days Hari'),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MenuAnchor(
                controller: controller,
                alignmentOffset: const Offset(0, 8),
                style: MenuStyle(
                  backgroundColor: const WidgetStatePropertyAll(Colors.white),
                  surfaceTintColor:
                      const WidgetStatePropertyAll(Colors.transparent),
                  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    side: BorderSide(
                        color: AppColors.grey200.withValues(alpha: 0.3)),
                  )),
                ),
                builder: (context, controller, child) => OutlinedButton.icon(
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  style: style.copyWith(
                    foregroundColor:
                        const WidgetStatePropertyAll(AppColors.greenDark),
                    backgroundColor:
                        const WidgetStatePropertyAll(AppColors.greenLight),
                  ),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Kustom'),
                      const SizedBox(width: 4),
                      Icon(
                          controller.isOpen
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16),
                    ],
                  ),
                ),
                menuChildren: [
                  AppCalendarRangePicker(
                    key: const ValueKey('report-range-calendar'),
                    initialRange: DateTimeRange(
                      start: range.start,
                      end: range.end,
                    ),
                    firstDate: DateTime(2000),
                    lastDate: lastDate,
                    onApply: (value) {
                      controller.close();
                      onChanged(DashboardReportRange(
                        start: value.start,
                        end: value.end,
                      ));
                    },
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(reportDateRangeCaption(range),
                    style:
                        AppTextStyle.small.copyWith(color: AppColors.grey100)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
