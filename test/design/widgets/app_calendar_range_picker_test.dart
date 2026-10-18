import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_calendar_range_picker.dart';

void main() {
  testWidgets('applies reversed date selection in chronological order',
      (tester) async {
    final applied = <DateTimeRange>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppCalendarRangePicker(
          initialRange: DateTimeRange(
            start: DateTime(2026, 6, 1),
            end: DateTime(2026, 6, 30),
          ),
          firstDate: DateTime(2026, 6, 1),
          lastDate: DateTime(2026, 6, 20),
          onApply: applied.add,
        ),
      ),
    ));

    final dateButton =
        find.byKey(const ValueKey('app-calendar-date-2026-06-20'));
    expect(tester.getSize(dateButton).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(dateButton).height, greaterThanOrEqualTo(48));

    await tester.tap(find.text('Reset'));
    await tester.tap(dateButton);
    await tester
        .tap(find.byKey(const ValueKey('app-calendar-date-2026-06-10')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terapkan'));

    expect(applied, [
      DateTimeRange(start: DateTime(2026, 6, 10), end: DateTime(2026, 6, 20)),
    ]);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('app-calendar-date-2026-06-21')),
          )
          .onPressed,
      isNull,
    );

    final startCell = tester.widget<Container>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('app-calendar-date-2026-06-10')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).color ==
                      AppColors.greenLight,
            ),
          )
          .first,
    );
    expect(
      (startCell.decoration! as BoxDecoration).borderRadius,
      const BorderRadius.horizontal(left: Radius.circular(8)),
    );

    final endCell = tester.widget<Container>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('app-calendar-date-2026-06-20')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).color ==
                      AppColors.greenLight,
            ),
          )
          .first,
    );
    expect(
      (endCell.decoration! as BoxDecoration).borderRadius,
      const BorderRadius.horizontal(right: Radius.circular(8)),
    );
  });
}
