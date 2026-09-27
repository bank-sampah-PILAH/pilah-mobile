import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

const _monthNames = [
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

const _weekdayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _weekdayShortNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String formatJadwalDayHeading(DateTime date, {DateTime? today}) {
  final reference = DateUtils.dateOnly(today ?? DateTime.now());
  final selected = DateUtils.dateOnly(date);
  final day = '${_weekdayNames[selected.weekday - 1]}, ${selected.day} '
      '${_monthNames[selected.month - 1]}';
  return DateUtils.isSameDay(selected, reference) ? 'Hari ini, $day' : day;
}

class JadwalCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Set<DateTime> scheduledDates;
  final bool isMonthExpanded;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<int> onNavigate;
  final VoidCallback onToggleMonth;

  const JadwalCalendar({
    super.key,
    required this.selectedDate,
    required this.scheduledDates,
    required this.isMonthExpanded,
    required this.onSelectDate,
    required this.onNavigate,
    required this.onToggleMonth,
  });

  bool _hasSchedule(DateTime date) =>
      scheduledDates.contains(DateUtils.dateOnly(date));

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        '${_monthNames[selectedDate.month - 1]} ${selectedDate.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    isMonthExpanded ? 'Bulan sebelumnya' : 'Minggu sebelumnya',
                visualDensity: VisualDensity.compact,
                onPressed: () => onNavigate(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip:
                    isMonthExpanded ? 'Bulan berikutnya' : 'Minggu berikutnya',
                visualDensity: VisualDensity.compact,
                onPressed: () => onNavigate(1),
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                key: const ValueKey('jadwal-calendar-toggle'),
                tooltip: isMonthExpanded
                    ? 'Tampilkan satu minggu'
                    : 'Tampilkan kalender sebulan',
                visualDensity: VisualDensity.compact,
                onPressed: onToggleMonth,
                icon: Icon(
                  isMonthExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isMonthExpanded ? _buildMonthGrid() : _buildWeekStrip(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    final monday = DateUtils.dateOnly(
      selectedDate,
    ).subtract(Duration(days: selectedDate.weekday - DateTime.monday));

    return Row(
      children: List.generate(7, (index) {
        final date = monday.add(Duration(days: index));
        return _JadwalDateCell(
          date: date,
          selected: DateUtils.isSameDay(date, selectedDate),
          hasSchedule: _hasSchedule(date),
          showWeekday: true,
          onTap: () => onSelectDate(date),
        );
      }),
    );
  }

  Widget _buildMonthGrid() {
    final firstOfMonth = DateTime(selectedDate.year, selectedDate.month);
    final offset = firstOfMonth.weekday - DateTime.monday;
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
    final weekCount = (offset + daysInMonth + 6) ~/ 7;
    final firstVisibleDay = firstOfMonth.subtract(Duration(days: offset));

    return Column(
      children: [
        Row(
          children: List.generate(
            7,
            (index) => Expanded(
              child: Center(
                child: Text(
                  _weekdayShortNames[index],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        for (var week = 0; week < weekCount; week++)
          Row(
            children: List.generate(7, (index) {
              final date = firstVisibleDay.add(
                Duration(days: week * 7 + index),
              );
              return _JadwalDateCell(
                date: date,
                selected: DateUtils.isSameDay(date, selectedDate),
                hasSchedule: _hasSchedule(date),
                showWeekday: false,
                isInDisplayedMonth: date.month == selectedDate.month,
                onTap: () => onSelectDate(date),
              );
            }),
          ),
      ],
    );
  }
}

class _JadwalDateCell extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool hasSchedule;
  final bool showWeekday;
  final bool isInDisplayedMonth;
  final VoidCallback onTap;

  const _JadwalDateCell({
    required this.date,
    required this.selected,
    required this.hasSchedule,
    required this.showWeekday,
    this.isInDisplayedMonth = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekdayLabel = _weekdayNames[date.weekday - 1];
    final monthLabel = _monthNames[date.month - 1];
    final semanticsLabel = '$weekdayLabel, ${date.day} $monthLabel'
        '${hasSchedule ? ', ada jadwal' : ''}'
        '${selected ? ', dipilih' : ''}';

    return Expanded(
      child: Semantics(
        label: semanticsLabel,
        button: true,
        selected: selected,
        child: InkWell(
          key: ValueKey('jadwal-date-${date.year}-${date.month}-${date.day}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: showWeekday ? 5 : 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showWeekday) ...[
                  Text(
                    _weekdayShortNames[date.weekday - 1],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.greenDark : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : isInDisplayedMonth
                              ? Colors.black87
                              : Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  key: hasSchedule
                      ? ValueKey(
                          'jadwal-marker-${date.year}-${date.month}-${date.day}',
                        )
                      : null,
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: hasSchedule
                        ? selected
                            ? Colors.white
                            : AppColors.greenDark
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
