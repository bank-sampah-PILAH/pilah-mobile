import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';

class _MockJadwalRepository extends Mock implements JadwalRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(_schedule());
    registerFallbackValue(DateTime(2026, 10, 10));
  });

  testWidgets('disables schedule submission while the save is pending', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    final pending = Completer<Either<NetworkException, JadwalEntity>>();
    _stubJadwal(repository, const []);
    when(
      () => repository.createJadwal(any()),
    ).thenAnswer((_) => pending.future);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Balai Warga');
    final submit = find.byType(ElevatedButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);

    pending.complete(Right(_schedule()));
    await tester.pumpAndSettle();
  });

  testWidgets('new schedule starts on the selected date', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    _stubJadwal(repository, const []);
    when(
      () => repository.createJadwal(any()),
    ).thenAnswer((_) async => Right(_schedule()));
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Balai Warga');
    final startTile = find.ancestor(
      of: find.text('Mulai'),
      matching: find.byType(GestureDetector),
    );
    await tester.ensureVisible(startTile);
    await tester.tap(startTile);
    await tester.pumpAndSettle();
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(DateUtils.isSameDay(picker.initialDate, DateTime.now()), isTrue);
  });

  testWidgets('failed initial load has an explicit retry action', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    var loadCount = 0;
    _stubCalendarDates(repository);
    when(() => repository.getJadwal(
          page: any(named: 'page'),
          date: any(named: 'date'),
        )).thenAnswer((_) async {
      loadCount++;
      return loadCount == 1
          ? Left(GeneralException(message: 'Koneksi gagal'))
          : Right(_page(const []));
    });
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Koneksi gagal'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada jadwal kegiatan'), findsOneWidget);
    expect(loadCount, 2);
  });

  testWidgets('empty state reloads schedules created by another manager', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    var loadCount = 0;
    _stubCalendarDates(repository);
    when(() => repository.getJadwal(
          page: any(named: 'page'),
          date: any(named: 'date'),
        )).thenAnswer((_) async {
      loadCount++;
      return loadCount == 1
          ? Right(_page(const []))
          : Right(_page([_schedule()]));
    });
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada jadwal kegiatan'), findsOneWidget);
    await tester.tap(find.text('Muat Ulang'));
    await tester.pumpAndSettle();

    expect(find.text('Balai Warga'), findsOneWidget);
    verify(() => repository.getJadwal(
          page: any(named: 'page'),
          date: any(named: 'date'),
        )).called(2);
  });

  testWidgets('pull-to-refresh reloads even a short schedule list', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    var loadCount = 0;
    _stubCalendarDates(repository);
    when(() => repository.getJadwal(
          page: any(named: 'page'),
          date: any(named: 'date'),
        )).thenAnswer((_) async {
      loadCount++;
      return Right(_page([_schedule()]));
    });
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<ListView>(find.byType(ListView)).physics,
      isA<AlwaysScrollableScrollPhysics>(),
    );
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
  });

  testWidgets('displays localized labels for every schedule status', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    final schedules = [
      _schedule(id: 'draft', location: 'Draft', status: 'draft'),
      _schedule(id: 'published', location: 'Published', status: 'diterbitkan'),
      _schedule(id: 'cancelled', location: 'Cancelled', status: 'dibatalkan'),
      _schedule(id: 'completed', location: 'Completed', status: 'selesai'),
    ];
    _stubJadwal(repository, schedules);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Draf', 'Diterbitkan', 'Dibatalkan', 'Selesai']) {
      await tester.scrollUntilVisible(find.text(label), 160);
      expect(find.text(label), findsOneWidget);
    }
    for (final status in ['draft', 'diterbitkan', 'dibatalkan', 'selesai']) {
      expect(find.text(status), findsNothing);
    }
  });

  testWidgets('shows the manager overlap warning when a schedule overlaps', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    _stubJadwal(repository, [_schedule(isOverlapping: true)]);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Jadwal bertumpuk di lokasi yang sama'),
      findsOneWidget,
    );
  });

  testWidgets('creates a schedule with the selected activity and details', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    JadwalEntity? submitted;
    _stubJadwal(repository, const []);
    when(() => repository.createJadwal(any())).thenAnswer((invocation) async {
      submitted = invocation.positionalArguments.single as JadwalEntity;
      return Right(submitted!);
    });
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Penimbangan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pencairan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Balai RW');
    await tester.enterText(
      find.byType(TextFormField).last,
      'Bawa buku tabungan',
    );
    final submit = find.widgetWithText(ElevatedButton, 'Simpan Jadwal');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submitted?.jenisKegiatan, 'pencairan');
    expect(submitted?.lokasi, 'Balai RW');
    expect(submitted?.keterangan, 'Bawa buku tabungan');
    expect(submitted?.cakupanPenerima, 'semua_nasabah');
    expect(find.byKey(const ValueKey('jadwal-form')), findsNothing);
  });

  testWidgets('requires a location before creating a schedule', (tester) async {
    final repository = _MockJadwalRepository();
    _stubJadwal(repository, const []);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(ElevatedButton, 'Simpan Jadwal');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Lokasi wajib diisi'), findsOneWidget);
    verifyNever(() => repository.createJadwal(any()));
  });

  testWidgets('rejects an end time that is not after the start time', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    final start = DateTime.now().add(const Duration(days: 1));
    final schedule = _schedule(
      start: start,
      end: start.subtract(const Duration(minutes: 1)),
    );
    _stubJadwal(repository, [schedule]);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();
    await _selectCalendarDate(tester, start);
    await tester.tap(find.text(schedule.lokasi));
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(ElevatedButton, 'Simpan Perubahan');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.text('Waktu selesai harus setelah waktu mulai'),
      findsOneWidget,
    );
    verifyNever(() => repository.updateJadwal(any()));
  });

  testWidgets('keeps the form open and shows the API error when save fails', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    _stubJadwal(repository, const []);
    when(() => repository.createJadwal(any())).thenAnswer(
      (_) async => Left(GeneralException(message: 'Jadwal gagal disimpan')),
    );
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Balai Warga');
    final submit = find.widgetWithText(ElevatedButton, 'Simpan Jadwal');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Jadwal gagal disimpan'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('jadwal-form')),
        matching: find.text('Buat Jadwal'),
      ),
      findsOneWidget,
    );
    verify(() => repository.createJadwal(any())).called(1);
  });

  testWidgets(
    'preserves selected recipients when editing a targeted schedule',
    (tester) async {
      final repository = _MockJadwalRepository();
      final target = _schedule(
        cakupanPenerima: 'nasabah_terpilih',
        penerimaIds: const ['member-1'],
      );
      JadwalEntity? submitted;
      _stubJadwal(repository, [target]);
      when(() => repository.updateJadwal(any())).thenAnswer((invocation) async {
        submitted = invocation.positionalArguments.single as JadwalEntity;
        return Right(target);
      });
      final cubit = JadwalCubit(repository);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const JadwalPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(target.lokasi));
      await tester.pumpAndSettle();

      expect(find.text('Nasabah terpilih'), findsOneWidget);
      final audienceField = find.text('Nasabah terpilih').first;
      await tester.ensureVisible(audienceField);
      await tester.tap(audienceField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nasabah terpilih').last);
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(ElevatedButton, 'Simpan Perubahan');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(submitted?.cakupanPenerima, 'nasabah_terpilih');
      expect(submitted?.penerimaIds, ['member-1']);
    },
  );

  testWidgets('new schedules cannot select an audience without a picker', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    _stubJadwal(repository, const []);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final audienceField = find.text('Semua nasabah');
    await tester.ensureVisible(audienceField);
    await tester.tap(audienceField);
    await tester.pumpAndSettle();

    expect(find.text('Nasabah terpilih'), findsNothing);
  });

  testWidgets('editing an end time preserves its date and clock time', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    _stubJadwal(repository, const []);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final endTile = find.ancestor(
      of: find.text('Selesai'),
      matching: find.byType(GestureDetector),
    );
    await tester.ensureVisible(endTile);
    final endSubtitle = find.descendant(
      of: endTile,
      matching: find.byType(Text),
    );
    final previousValue = tester.widget<Text>(endSubtitle.last).data!;

    await tester.tap(endTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text(previousValue), findsOneWidget);
  });

  testWidgets('past schedules open the picker and preserve their time', (
    tester,
  ) async {
    final repository = _MockJadwalRepository();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 7, 18, 30);
    final schedule = _schedule(
      start: start,
      end: start.add(const Duration(hours: 2)),
    );
    _stubJadwal(repository, [schedule]);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();
    await _selectCalendarDate(tester, start);
    await tester.tap(find.text(schedule.lokasi));
    await tester.pumpAndSettle();
    final startTile = find.ancestor(
      of: find.text('Mulai'),
      matching: find.byType(GestureDetector),
    );
    await tester.ensureVisible(startTile);
    await tester.tap(startTile);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('18:30'), findsNWidgets(2));
  });
}

void _stubJadwal(_MockJadwalRepository repository, List<JadwalEntity> items) {
  _stubCalendarDates(repository);
  when(() => repository.getJadwal(
        page: any(named: 'page'),
        date: any(named: 'date'),
      )).thenAnswer((_) async => Right(_page(items)));
}

void _stubCalendarDates(_MockJadwalRepository repository) {
  when(() => repository.getCalendarDates(any(), any()))
      .thenAnswer((_) async => const Right({}));
}

JadwalPageResult _page(List<JadwalEntity> items) => JadwalPageResult(
      items: items,
      totalCount: items.length,
      hasMore: false,
    );

JadwalEntity _schedule({
  String id = 'schedule-1',
  String location = 'Balai Warga',
  DateTime? start,
  DateTime? end,
  String status = 'draft',
  String cakupanPenerima = 'semua_nasabah',
  List<String> penerimaIds = const [],
  bool isOverlapping = false,
}) {
  final startsAt =
      start ?? DateUtils.dateOnly(DateTime.now()).add(const Duration(hours: 9));
  return JadwalEntity(
    id: id,
    bankSampahId: 'bank-1',
    jenisKegiatan: 'penimbangan',
    mulaiPada: startsAt,
    selesaiPada: end ?? startsAt.add(const Duration(hours: 2)),
    lokasi: location,
    cakupanPenerima: cakupanPenerima,
    penerimaIds: penerimaIds,
    status: status,
    isOverlapping: isOverlapping,
  );
}

Future<void> _selectCalendarDate(WidgetTester tester, DateTime date) async {
  final today = DateTime.now();
  final monthDifference =
      (date.year - today.year) * 12 + date.month - today.month;
  await tester.tap(find.byKey(const ValueKey('jadwal-calendar-toggle')));
  await tester.pumpAndSettle();
  for (var step = 0; step < monthDifference.abs(); step++) {
    await tester.tap(
      find.byTooltip(
        monthDifference < 0 ? 'Bulan sebelumnya' : 'Bulan berikutnya',
      ),
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(
    find.byKey(
      ValueKey('jadwal-date-${date.year}-${date.month}-${date.day}'),
    ),
  );
  await tester.pumpAndSettle();
}
