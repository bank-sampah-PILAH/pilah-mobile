import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Selects and applies a bounded, inclusive date range from a calendar.
class AppCalendarRangePicker extends StatefulWidget {
  const AppCalendarRangePicker({
    super.key,
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
    required this.onApply,
    this.applyLabel = 'Terapkan',
    this.width = 336,
  });

  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTimeRange> onApply;
  final String applyLabel;
  final double width;

  @override
  State<AppCalendarRangePicker> createState() => _AppCalendarRangePickerState();
}

class _AppCalendarRangePickerState extends State<AppCalendarRangePicker> {
  late DateTime _month;
  late DateTime? _start;
  late DateTime? _end;

  DateTime get _firstDate => DateUtils.dateOnly(widget.firstDate);
  DateTime get _lastDate => DateUtils.dateOnly(widget.lastDate);

  @override
  void initState() {
    super.initState();
    _month = DateTime(
        widget.initialRange.start.year, widget.initialRange.start.month);
    _start = DateUtils.dateOnly(widget.initialRange.start);
    _end = DateUtils.dateOnly(widget.initialRange.end);
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

  String _dateLabel(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  bool _isInRange(DateTime day) =>
      _start != null &&
      _end != null &&
      !day.isBefore(_start!) &&
      !day.isAfter(_end!);

  Widget _day(BuildContext context, DateTime day, int column) {
    final endpoint =
        DateUtils.isSameDay(day, _start) || DateUtils.isSameDay(day, _end);
    final inRange = _isInRange(day);
    final roundsLeft =
        column == 0 || !_isInRange(DateTime(day.year, day.month, day.day - 1));
    final roundsRight =
        column == 6 || !_isInRange(DateTime(day.year, day.month, day.day + 1));
    final enabled = !day.isBefore(_firstDate) && !day.isAfter(_lastDate);
    return Container(
      decoration: inRange
          ? BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.horizontal(
                left: roundsLeft ? const Radius.circular(8) : Radius.zero,
                right: roundsRight ? const Radius.circular(8) : Radius.zero,
              ),
            )
          : null,
      child: Semantics(
        label: MaterialLocalizations.of(context).formatFullDate(day),
        button: true,
        selected: endpoint || inRange,
        child: TextButton(
          key: ValueKey('app-calendar-date-${_dateKey(day)}'),
          onPressed: enabled ? () => _select(day) : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: endpoint ? Colors.white : AppColors.black,
            backgroundColor:
                endpoint ? AppColors.greenDark : Colors.transparent,
            shape: const CircleBorder(),
            textStyle: AppTextStyle.small,
          ),
          child: Text('${day.day}'),
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
                    height: 48,
                    child: week * 7 + column >= offset &&
                            week * 7 + column < offset + days
                        ? _day(
                            context,
                            DateTime(
                              _month.year,
                              _month.month,
                              week * 7 + column - offset + 1,
                            ),
                            column,
                          )
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
    final firstMonth = DateTime(_firstDate.year, _firstDate.month);
    final lastMonth = DateTime(_lastDate.year, _lastDate.month);

    return SizedBox(
      key: const ValueKey('app-calendar-range-picker'),
      width: widget.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              IconButton(
                tooltip: localizations.previousMonthTooltip,
                onPressed: _month.isAfter(firstMonth)
                    ? () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1))
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  localizations.formatMonthYear(_month),
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyle.small.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: localizations.nextMonthTooltip,
                onPressed: _month.isBefore(lastMonth)
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
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            _calendarGrid(offset, days),
            const Divider(height: 24),
            Text(
              _start == null
                  ? 'Pilih tanggal mulai dan selesai'
                  : _end == null
                      ? 'Mulai ${_dateLabel(_start!)} — pilih tanggal selesai'
                      : '${_dateLabel(_start!)} – ${_dateLabel(_end!)}',
              style: AppTextStyle.extraSmall,
            ),
            const SizedBox(height: 8),
            Row(children: [
              TextButton(
                onPressed: () => setState(() {
                  _start = null;
                  _end = null;
                }),
                child: Text(
                  'Reset',
                  style:
                      AppTextStyle.small.copyWith(color: AppColors.greenDark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _start != null && _end != null
                      ? () => widget.onApply(
                            DateTimeRange(start: _start!, end: _end!),
                          )
                      : null,
                  child: Text(widget.applyLabel),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
