import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_upcoming_dates.dart';

void main() {
  final today = DateTime(2026, 10, 19);

  Future<List<DateTime>> pump(
    WidgetTester tester,
    Set<DateTime> dates, {
    DateTime? selected,
    int limit = 4,
  }) async {
    final tapped = <DateTime>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: JadwalUpcomingDates(
          scheduledDates: dates,
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

  testWidgets('shows at most the limit', (tester) async {
    await pump(
      tester,
      {for (var d = 20; d <= 26; d++) DateTime(2026, 10, d)},
      limit: 3,
    );

    expect(find.byType(InkWell), findsNWidgets(3));
  });

  testWidgets('tapping a date selects it', (tester) async {
    final tapped = await pump(tester, {DateTime(2026, 10, 22)});

    await tester.tap(find.text('Kamis, 22 Oktober'));

    expect(tapped, [DateTime(2026, 10, 22)]);
  });

  testWidgets('says so when nothing is coming up', (tester) async {
    await pump(tester, {DateTime(2026, 10, 1)});

    expect(find.text('Belum ada jadwal mendatang.'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });
}
