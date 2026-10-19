import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_upcoming_months.dart';

void main() {
  final today = DateTime(2026, 10, 19);

  Future<List<DateTime>> pump(
    WidgetTester tester,
    Set<DateTime> dates,
  ) async {
    final tapped = <DateTime>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: JadwalUpcomingMonths(
          upcomingDates: dates,
          today: today,
          onSelect: tapped.add,
        ),
      ),
    ));
    return tapped;
  }

  testWidgets('summarises each later month by its scheduled days',
      (tester) async {
    await pump(tester, {
      DateTime(2026, 10, 22),
      DateTime(2026, 11, 3),
      DateTime(2026, 11, 17),
      DateTime(2026, 12, 9),
    });

    expect(find.text('Bulan berikutnya'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('2 hari berjadwal'), findsOneWidget);
    expect(find.text('Desember 2026'), findsOneWidget);
    expect(find.text('1 hari berjadwal'), findsOneWidget);
  });

  testWidgets('the current month is left to the agenda', (tester) async {
    await pump(tester, {DateTime(2026, 10, 22), DateTime(2026, 11, 3)});

    expect(find.text('Oktober 2026'), findsNothing);
    expect(find.textContaining('22 Oktober'), findsNothing,
        reason: 'single dates are not listed any more');
  });

  testWidgets('earlier dates never count', (tester) async {
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

  testWidgets('tapping a month jumps to its first scheduled day',
      (tester) async {
    final tapped = await pump(tester, {
      DateTime(2026, 11, 17),
      DateTime(2026, 11, 3),
    });

    await tester.tap(find.text('November 2026'));

    expect(tapped, [DateTime(2026, 11, 3)]);
  });

  testWidgets('says plainly that no later month has anything scheduled',
      (tester) async {
    await pump(tester, {DateTime(2026, 10, 22)});

    expect(
        find.text('Belum ada jadwal dalam 3 bulan ke depan.'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}
