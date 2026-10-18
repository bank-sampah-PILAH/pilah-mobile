import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';

const _indonesianMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _reportDateIndonesian(DateTime date) =>
    '${date.day} ${_indonesianMonths[date.month - 1]} ${date.year}';

String reportDateRangeCaption(DashboardReportRange range) =>
    'Menampilkan ${_reportDateIndonesian(range.start)} sampai '
    '${_reportDateIndonesian(range.end)}';

String reportCategoryWeightSubtitle(DashboardReportRange range) {
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
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      side: BorderSide(color: AppColors.greenDark.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  _ReportRangeCalendar(
                    range: range,
                    onChanged: (value) {
                      controller.close();
                      onChanged(value);
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

class _ReportRangeCalendar extends StatefulWidget {
  final DashboardReportRange range;
  final ValueChanged<DashboardReportRange> onChanged;

  const _ReportRangeCalendar({required this.range, required this.onChanged});

  @override
  State<_ReportRangeCalendar> createState() => _ReportRangeCalendarState();
}

class _ReportRangeCalendarState extends State<_ReportRangeCalendar> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.range.start.year, widget.range.start.month);
    _start = widget.range.start;
    _end = widget.range.end;
  }

  DateTime get _lastDate {
    final today = DateUtils.dateOnly(DateTime.now());
    return widget.range.end.isAfter(today) ? widget.range.end : today;
  }

  void _select(DateTime day) {
    setState(() {
      if (_start == null || _end != null) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _end = _start;
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  Widget _day(DateTime day) {
    final endpoint =
        DateUtils.isSameDay(day, _start) || DateUtils.isSameDay(day, _end);
    final inRange = _start != null &&
        _end != null &&
        !day.isBefore(_start!) &&
        !day.isAfter(_end!);
    return Container(
      color: inRange ? AppColors.greenLight : Colors.transparent,
      child: Semantics(
        selected: endpoint || inRange,
        child: TextButton(
          key: ValueKey('report-date-${reportDate(day)}'),
          onPressed: day.isAfter(_lastDate) ? null : () => _select(day),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: endpoint ? Colors.white : AppColors.black,
            backgroundColor:
                endpoint ? AppColors.greenDark : Colors.transparent,
            shape: const CircleBorder(),
            textStyle: AppTextStyle.small,
          ),
          child: Text('${day.day}',
              semanticsLabel:
                  MaterialLocalizations.of(context).formatFullDate(day)),
        ),
      ),
    );
  }

  Widget _calendarGrid(int offset, int days) => Column(
        children: [
          for (var week = 0; week < ((offset + days) / 7).ceil(); week++)
            Row(children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: week * 7 + column >= offset &&
                            week * 7 + column < offset + days
                        ? _day(DateTime(_month.year, _month.month,
                            week * 7 + column - offset + 1))
                        : const SizedBox.shrink(),
                  ),
                ),
            ]),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final offset =
        (_month.weekday % 7 - localizations.firstDayOfWeekIndex + 7) % 7;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    return SizedBox(
      key: const ValueKey('report-range-calendar'),
      width: 336,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              IconButton(
                tooltip: localizations.previousMonthTooltip,
                onPressed: _month.isAfter(DateTime(2000))
                    ? () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1))
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                  child: Text(localizations.formatMonthYear(_month),
                      textAlign: TextAlign.center,
                      style: AppTextStyle.small
                          .copyWith(fontWeight: FontWeight.w600))),
              IconButton(
                tooltip: localizations.nextMonthTooltip,
                onPressed: _month
                        .isBefore(DateTime(_lastDate.year, _lastDate.month))
                    ? () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1))
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ]),
            Row(children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                    child: Text(
                  localizations.narrowWeekdays[
                      (i + localizations.firstDayOfWeekIndex) % 7],
                  textAlign: TextAlign.center,
                  style: AppTextStyle.extraSmall,
                )),
            ]),
            const SizedBox(height: 8),
            _calendarGrid(offset, days),
            const Divider(height: 24),
            Text(
              _start == null || _end == null
                  ? 'Pilih tanggal mulai dan selesai'
                  : '${reportDate(_start!)} – ${reportDate(_end!)}',
              style: AppTextStyle.extraSmall,
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(
                onPressed: () => setState(() {
                  _start = null;
                  _end = null;
                }),
                child: Text('Reset',
                    style: AppTextStyle.small
                        .copyWith(color: AppColors.greenDark)),
              ),
              FilledButton(
                onPressed: _start != null && _end != null
                    ? () => widget.onChanged(
                        DashboardReportRange(start: _start!, end: _end!))
                    : null,
                child: const Text('Terapkan'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
