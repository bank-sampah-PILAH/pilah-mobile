import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_upcoming_dates.dart';

void main() {
  final today = DateTime(2026, 10, 19);

  Future<List<DateTime>> pump(
    WidgetTester tester,
    Set<DateTime> dates, {
    DateTime? selected,
    int limit = 3,
  }) async {
    final tapped = <DateTime>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: JadwalUpcomingDates(
          upcomingDates: dates,
          today: today,
          selectedDate: selected ?? today,
          onSelect: tapped.add,
          limit: limit,
        ),
      ),
    ));
    return tapped;
  }

  testWidgets('lists the scheduled dates from today on, soonest first',
      (tester) async {
    await pump(tester, {
      DateTime(2026, 10, 24),
      DateTime(2026, 10, 15),
      DateTime(2026, 10, 22),
    });

    expect(find.text('Berikutnya'), findsOneWidget);
    expect(find.text('Kamis, 22 Oktober'), findsOneWidget);
    expect(find.text('Sabtu, 24 Oktober'), findsOneWidget);
    expect(find.textContaining('15 Oktober'), findsNothing,
        reason: 'a past date is not upcoming');
    expect(tester.getTopLeft(find.text('Kamis, 22 Oktober')).dy,
        lessThan(tester.getTopLeft(find.text('Sabtu, 24 Oktober')).dy));
  });

  testWidgets('today counts as upcoming', (tester) async {
    await pump(tester, {today});

    expect(find.text('Hari ini, Senin, 19 Oktober'), findsOneWidget);
  });

  testWidgets('shows at most the limit of nearest dates', (tester) async {
    await pump(
      tester,
      {for (var d = 20; d <= 26; d++) DateTime(2026, 10, d)},
      limit: 2,
    );

    expect(find.byType(InkWell), findsNWidgets(2));
  });

  testWidgets('tapping a date selects it', (tester) async {
    final tapped = await pump(tester, {DateTime(2026, 10, 22)});

    await tester.tap(find.text('Kamis, 22 Oktober'));

    expect(tapped, [DateTime(2026, 10, 22)]);
  });

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
    expect(find.text('Oktober 2026'), findsNothing,
        reason: 'the current month is covered by the nearest dates');
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

  testWidgets('without later months the month section is not shown',
      (tester) async {
    await pump(tester, {DateTime(2026, 10, 22)});

    expect(find.text('Bulan berikutnya'), findsNothing);
  });

  testWidgets('says plainly that nothing is scheduled ahead', (tester) async {
    await pump(tester, {DateTime(2026, 10, 1)});

    expect(
        find.text('Belum ada jadwal dalam 3 bulan ke depan.'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}
