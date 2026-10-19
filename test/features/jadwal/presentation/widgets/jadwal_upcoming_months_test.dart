import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_upcoming_months.dart';

void main() {
  final today = DateTime(2026, 10, 19);

  Future<List<DateTime>> pump(
    WidgetTester tester,
    Set<DateTime> dates, {
    DateTime? selected,
  }) async {
    final tapped = <DateTime>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: JadwalUpcomingMonths(
          upcomingDates: dates,
          today: today,
          selectedDate: selected ?? today,
          onSelect: tapped.add,
        ),
      ),
    ));
    return tapped;
  }

  testWidgets('lists this month from today on, then each later month',
      (tester) async {
    await pump(tester, {
      DateTime(2026, 10, 15),
      DateTime(2026, 10, 22),
      DateTime(2026, 10, 24),
      DateTime(2026, 11, 3),
      DateTime(2026, 11, 17),
      DateTime(2026, 12, 9),
    });

    expect(find.text('Berikutnya'), findsOneWidget);
    expect(find.text('Bulan ini'), findsOneWidget);
    expect(find.text('2 hari berjadwal'), findsNWidgets(2),
        reason: 'this month counts 22 and 24 Oct, not the passed 15 Oct');
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('Desember 2026'), findsOneWidget);
    expect(find.text('1 hari berjadwal'), findsOneWidget);
    expect(find.text('Oktober 2026'), findsNothing);
  });

  testWidgets('today still counts as not yet passed', (tester) async {
    await pump(tester, {today});

    expect(find.text('Bulan ini'), findsOneWidget);
    expect(find.text('1 hari berjadwal'), findsOneWidget);
  });

  testWidgets('this month is left out when nothing is left in it',
      (tester) async {
    await pump(tester, {DateTime(2026, 10, 3), DateTime(2026, 11, 3)});

    expect(find.text('Bulan ini'), findsNothing);
    expect(find.text('November 2026'), findsOneWidget);
  });

  testWidgets('earlier months never count', (tester) async {
    await pump(tester, {DateTime(2026, 9, 30), DateTime(2026, 11, 3)});

    expect(find.text('September 2026'), findsNothing);
    expect(find.text('1 hari berjadwal'), findsOneWidget);
  });

  testWidgets('months come in calendar order, across a year end',
      (tester) async {
    await pump(tester, {
      DateTime(2027, 1, 5),
      DateTime(2026, 12, 9),
      DateTime(2026, 11, 3),
    });

    final tops = [
      for (final m in ['November 2026', 'Desember 2026', 'Januari 2027'])
        tester.getTopLeft(find.text(m)).dy,
    ];
    expect(tops, [...tops]..sort());
  });

  testWidgets('tapping this month opens its first day that has not passed',
      (tester) async {
    final tapped = await pump(tester, {
      DateTime(2026, 10, 15),
      DateTime(2026, 10, 24),
      DateTime(2026, 10, 22),
    });

    await tester.tap(find.text('Bulan ini'));

    expect(tapped, [DateTime(2026, 10, 22)]);
  });

  testWidgets('tapping a later month jumps to its first scheduled day',
      (tester) async {
    final tapped = await pump(tester, {
      DateTime(2026, 11, 17),
      DateTime(2026, 11, 3),
    });

    await tester.tap(find.text('November 2026'));

    expect(tapped, [DateTime(2026, 11, 3)]);
  });

  testWidgets('the month holding the selected day is tinted', (tester) async {
    await pump(
      tester,
      {DateTime(2026, 10, 22), DateTime(2026, 11, 3)},
      selected: DateTime(2026, 11, 3),
    );

    bool tinted(String label) => tester
        .widgetList<Container>(find.ancestor(
            of: find.text(label), matching: find.byType(Container)))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .any((d) => d.color == AppColors.greenLight);

    expect(tinted('November 2026'), isTrue);
    expect(tinted('Bulan ini'), isFalse);
  });

  testWidgets('says plainly that nothing is scheduled ahead', (tester) async {
    await pump(tester, {DateTime(2026, 10, 1)});

    expect(find.text('Belum ada jadwal mendatang dalam 3 bulan ke depan.'),
        findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}
