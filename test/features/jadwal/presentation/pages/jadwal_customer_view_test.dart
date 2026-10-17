import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';

class _MockJadwalCubit extends MockCubit<JadwalState> implements JadwalCubit {}

void main() {
  testWidgets('customer sees only published schedules in a read-only view', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final cubit = _MockJadwalCubit();
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
    when(() => cubit.state).thenReturn(
      JadwalLoaded(schedules, scheduledDates: {today}, totalCount: 1),
    );
    when(() => cubit.loadJadwal(date: today)).thenAnswer((_) async {});
    _stubCalendarLoad(cubit, today);

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage(customerMode: true)),
      ),
    );
    await tester.pump();

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

  testWidgets('customer can select a date and sees a read-only empty state', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = today.add(
      Duration(days: today.weekday == DateTime.sunday ? -1 : 1),
    );
    final cubit = _MockJadwalCubit();
    when(() => cubit.state).thenReturn(
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
    );
    when(() => cubit.loadJadwal(date: today)).thenAnswer((_) async {});
    when(() => cubit.loadJadwal(date: selectedDate)).thenAnswer((_) async {});
    _stubCalendarLoad(cubit, today);
    if (selectedDate.month != today.month || selectedDate.year != today.year) {
      _stubCalendarLoad(cubit, selectedDate);
    }

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage(customerMode: true)),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(
        ValueKey(
          'jadwal-date-${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
        ),
      ),
    );
    await tester.pump();

    verify(() => cubit.loadJadwal(date: selectedDate)).called(1);
    expect(find.text(formatJadwalDayHeading(selectedDate)), findsOneWidget);
    expect(find.text('Belum ada jadwal kegiatan'), findsOneWidget);
    expect(find.text('Buat Jadwal'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
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

void _stubCalendarLoad(_MockJadwalCubit cubit, DateTime date) {
  final first = DateTime(date.year, date.month, 1);
  final offset = first.weekday - DateTime.monday;
  final firstVisible = first.subtract(Duration(days: offset));
  final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
  final weekCount = (offset + daysInMonth + 6) ~/ 7;
  final lastVisible = firstVisible.add(Duration(days: weekCount * 7 - 1));
  when(
    () =>
        cubit.loadCalendarDates(startDate: firstVisible, endDate: lastVisible),
  ).thenAnswer((_) async {});
}
