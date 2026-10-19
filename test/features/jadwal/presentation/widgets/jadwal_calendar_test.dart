import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required bool month}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: JadwalCalendar(
          selectedDate: DateTime(2026, 10, 3),
          scheduledDates: const {},
          isMonthExpanded: month,
          onSelectDate: (_) {},
          onNavigate: (_) {},
          onToggleMonth: () {},
        ),
      ),
    ));
  }

  for (final month in [true, false]) {
    testWidgets(
        'the month name has room above the weekday row '
        '(${month ? 'month' : 'week'})', (tester) async {
      await pump(tester, month: month);

      final title = tester.getRect(find.text('Oktober 2026'));
      final weekdays = tester.getRect(find.text('Sen'));

      expect(weekdays.top - title.bottom, greaterThanOrEqualTo(16));
    });
  }
}
