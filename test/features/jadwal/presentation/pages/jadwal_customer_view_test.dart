import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';
import '../../../../support/jadwal_provider_support.dart';

void main() {
  testWidgets('customer sees only published schedules in a read-only view', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final schedules = [
      _schedule(
        id: 'published',
        location: 'Balai Warga',
        status: 'diterbitkan',
        isOverlapping: true,
      ),
      _schedule(id: 'draft', location: 'Draf', status: 'draft'),
      _schedule(id: 'cancelled', location: 'Dibatalkan', status: 'dibatalkan'),
      _schedule(id: 'completed', location: 'Selesai', status: 'selesai'),
    ];
    await _pumpCustomer(
        tester,
        JadwalLoaded(
          schedules,
          scheduledDates: {today},
          totalCount: 1,
        ));

    expect(find.text('Balai Warga'), findsOneWidget);
    expect(find.text('Penimbangan Sampah'), findsOneWidget);
    expect(find.byType(JadwalCalendar), findsOneWidget);
    expect(find.text(formatJadwalDayHeading(today)), findsOneWidget);
    expect(find.text('Draf'), findsNothing);
    expect(find.text('Dibatalkan'), findsNothing);
    expect(find.text('Selesai'), findsNothing);
    expect(find.textContaining('Diterbitkan'), findsOneWidget);
    expect(find.textContaining('diterbitkan'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
    expect(find.text('Tandai Selesai'), findsNothing);
    expect(find.text('Buat Jadwal'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            widget.message == 'Jadwal bertumpuk di lokasi yang sama',
      ),
      findsNothing,
    );

    await tester.tap(find.text('Balai Warga'));
    await tester.pump();
    expect(find.text('Ubah Jadwal'), findsNothing);
  });

  testWidgets('customer pull-to-refresh reloads visible calendar dates', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final agendaLoads = <({bool silent, DateTime? date})>[];
    final calendarLoads = <(DateTime, DateTime)>[];
    await _pumpCustomer(
      tester,
      const JadwalLoaded([]),
      onLoadJadwal: (
          {bool silent = false, DateTime? date, DateTime? dateTo}) async {
        agendaLoads.add((silent: silent, date: date));
      },
      onLoadCalendarDates: ({required startDate, required endDate}) async {
        calendarLoads.add((startDate, endDate));
      },
    );

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(
      agendaLoads.where((call) => call.silent && call.date == today),
      hasLength(1),
    );
    expect(calendarLoads, hasLength(2));
  });

  testWidgets('customer can select a date and sees a read-only empty state', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = today.add(
      Duration(days: today.weekday == DateTime.sunday ? -1 : 1),
    );
    final agendaLoads = <DateTime?>[];
    await _pumpCustomer(
      tester,
      JadwalLoaded(
        [
          _schedule(
            id: 'published',
            location: 'Balai Warga',
            status: 'diterbitkan',
          ),
        ],
        scheduledDates: {today},
        totalCount: 1,
      ),
      onLoadJadwal: ({date, bool silent = false, dateTo}) async {
        if (!silent) agendaLoads.add(date);
      },
    );

    await tester.tap(
      find.byKey(
        ValueKey(
          'jadwal-date-${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
        ),
      ),
    );
    await tester.pump();

    expect(agendaLoads, contains(selectedDate));
    expect(find.text(formatJadwalDayHeading(selectedDate)), findsOneWidget);
    expect(find.text('Belum ada jadwal kegiatan'), findsOneWidget);
    expect(find.text('Buat Jadwal'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}

Future<TestJadwalNotifier> _pumpCustomer(
  WidgetTester tester,
  JadwalState initialState, {
  Future<void> Function({
    bool silent,
    DateTime? date,
    DateTime? dateTo,
  })? onLoadJadwal,
  Future<void> Function({
    required DateTime startDate,
    required DateTime endDate,
  })? onLoadCalendarDates,
}) async {
  final notifier = TestJadwalNotifier(
    repository: UnusedJadwalRepository(),
    initialState: initialState,
    onLoadJadwal: onLoadJadwal,
    onLoadCalendarDates: onLoadCalendarDates,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [jadwalProvider.overrideWith(() => notifier)],
      child: const MaterialApp(home: JadwalPage(customerMode: true)),
    ),
  );
  await tester.pump();
  return notifier;
}

JadwalEntity _schedule({
  required String id,
  required String location,
  required String status,
  bool isOverlapping = false,
}) {
  final start = _todayAt(9).toUtc();
  return JadwalEntity(
    id: id,
    bankSampahId: 'bank-1',
    jenisKegiatan: 'penimbangan',
    mulaiPada: start,
    selesaiPada: start.add(const Duration(hours: 2)),
    lokasi: location,
    status: status,
    isOverlapping: isOverlapping,
  );
}

DateTime _todayAt(int hour) {
  final today = DateUtils.dateOnly(DateTime.now());
  return DateTime(today.year, today.month, today.day, hour);
}
