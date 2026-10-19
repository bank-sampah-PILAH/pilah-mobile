import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_reporting.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_range_filter.dart';

void main() {
  final june = DashboardReportRange(
      start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 30));

  Future<void> pumpFilter(
      WidgetTester tester, List<DashboardReportRange> changes,
      {DashboardReportRange? initialRange}) async {
    var range = initialRange ?? june;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: StatefulBuilder(
              builder: (context, setState) => DashboardReportRangeFilter(
                  range: range,
                  onChanged: (value) {
                    changes.add(value);
                    setState(() => range = value);
                  }))),
    ));
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Kustom'));
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String date) async {
    await tester.tap(find.byKey(ValueKey('app-calendar-date-$date')));
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(1440, 900), const Size(375, 844)]) {
    testWidgets(
        'custom calendar is a compact anchored panel at ${size.width}px',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final changes = <DashboardReportRange>[];
      await pumpFilter(tester, changes);
      final custom =
          tester.getRect(find.widgetWithText(OutlinedButton, 'Kustom'));
      final caption = tester
          .getRect(find.text('Menampilkan 1 Juni 2026 sampai 30 Juni 2026'));
      expect(caption.left, greaterThan(custom.right));
      expect(caption.center.dy, closeTo(custom.center.dy, 1));
      for (final label in ['Hari ini', '7 Hari', '30 Hari', 'Kustom']) {
        expect(
            tester.getSize(find.widgetWithText(OutlinedButton, label)).height,
            48);
      }
      await open(tester);
      final panel = find.byKey(const ValueKey('report-range-calendar'));
      expect(find.text('01/06/2026 – 30/06/2026'), findsOneWidget);
      final bounds = tester.getRect(panel);
      expect(bounds.width, lessThanOrEqualTo(336));
      expect(bounds.height, lessThan(size.height));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(find.byType(DateRangePickerDialog), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tapAt(Offset(size.width - 4, size.height - 4));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(changes, isEmpty);
      await open(tester);
      await tester.tap(find.text('Kustom'));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
    });
  }

  testWidgets('range captions use full Indonesian month names', (tester) async {
    final range = DashboardReportRange(
        start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31));
    await pumpFilter(tester, [], initialRange: range);

    expect(find.text('Menampilkan 1 Oktober 2026 sampai 31 Oktober 2026'),
        findsOneWidget);
    expect(reportCategoryWeightSubtitle(range),
        'Berat per kategori, 1 sampai 31 Oktober 2026');
    expect(
      reportCategoryWeightSubtitle(DashboardReportRange(
          start: DateTime(2026, 10, 5), end: DateTime(2026, 10, 5))),
      'Berat per kategori, 5 Oktober 2026',
    );
    expect(
      reportCategoryWeightSubtitle(DashboardReportRange(
          start: DateTime(2026, 9, 30), end: DateTime(2026, 10, 2))),
      'Berat per kategori, 30 September 2026 sampai 2 Oktober 2026',
    );
  });

  testWidgets(
      'presets select inclusive trailing ranges and mark the active button',
      (tester) async {
    final changes = <DashboardReportRange>[];
    await pumpFilter(tester, changes);
    final today = DateUtils.dateOnly(DateTime.now());
    for (final days in [30, 7, 1]) {
      final label = days == 1 ? 'Hari ini' : '$days Hari';
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(changes.last.start,
          DateTime(today.year, today.month, today.day - days + 1));
      expect(changes.last.end, today);
      final button = tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, label));
      expect(button.style!.backgroundColor!.resolve({}), AppColors.greenDark);
    }
  });

  testWidgets('custom range can run backward, reset, and span months',
      (tester) async {
    final changes = <DashboardReportRange>[];
    await pumpFilter(tester, changes);
    await open(tester);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await select(tester, '2026-06-20');
    await select(tester, '2026-06-10');
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();
    expect(changes.single.start, DateTime(2026, 6, 10));
    expect(changes.single.end, DateTime(2026, 6, 20));
    expect(find.byKey(const ValueKey('report-range-calendar')), findsNothing);

    await open(tester);
    await select(tester, '2026-06-25');
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await select(tester, '2026-07-05');
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();
    expect(changes.last.start, DateTime(2026, 6, 25));
    expect(changes.last.end, DateTime(2026, 7, 5));
  });

  testWidgets('calendar navigation respects the first and last allowed months',
      (tester) async {
    final changes = <DashboardReportRange>[];
    await pumpFilter(tester, changes,
        initialRange: DashboardReportRange(
          start: DateTime(2000),
          end: DateTime(2000, 1, 31),
        ));
    await open(tester);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_left))
            .onPressed,
        isNull);
    await tester.tapAt(const Offset(790, 590));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFilter(tester, changes,
        initialRange: DashboardReportRange(
          start: DateTime(2099, 6),
          end: DateTime(2099, 6, 10),
        ));
    await open(tester);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_right))
            .onPressed,
        isNull);
    final disabled = tester.widget<TextButton>(
        find.byKey(const ValueKey('app-calendar-date-2099-06-11')));
    expect(disabled.onPressed, isNull);
    await select(tester, '2099-06-10');
    await select(tester, '2099-06-10');
    expect(find.text('10/06/2099 – 10/06/2099'), findsOneWidget);
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();
    expect(changes.single.start, changes.single.end);
  });
}
