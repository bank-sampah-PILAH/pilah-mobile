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
  final today = DateUtils.dateOnly(DateTime.now());
  late _MockJadwalRepository repository;
  late JadwalCubit cubit;

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 10, 10));
    registerFallbackValue(_schedule());
  });

  setUp(() {
    repository = _MockJadwalRepository();
    when(() => repository.getCalendarDates(any(), any()))
        .thenAnswer((_) async => const Right({}));
    cubit = JadwalCubit(repository);
  });

  tearDown(() => cubit.close());

  // Tall enough that the footer below the agenda is built (lists are lazy).
  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app({DateTime? initialDate, bool customerMode = false}) => MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child:
              JadwalPage(initialDate: initialDate, customerMode: customerMode),
        ),
      );

  void answerPage1(List<JadwalEntity> items, {bool hasMore = false}) {
    when(() => repository.getJadwal(
          page: 1,
          date: any(named: 'date'),
        )).thenAnswer((_) async => Right(JadwalPageResult(
          items: items,
          totalCount: items.length,
          hasMore: hasMore,
        )));
  }

  group('date driven by the parent', () {
    testWidgets('follows a new initial date and falls back to today',
        (tester) async {
      answerPage1(const []);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final target = today.add(const Duration(days: 3));
      await tester.pumpWidget(app(initialDate: target));
      await tester.pumpAndSettle();
      verify(() => repository.getJadwal(page: 1, date: target)).called(1);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      verify(() => repository.getJadwal(page: 1, date: today)).called(2);
    });

    testWidgets('weekly arrows move the selected day by seven days',
        (tester) async {
      answerPage1(const []);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Minggu berikutnya'));
      await tester.pumpAndSettle();

      verify(() => repository.getJadwal(
          page: 1, date: today.add(const Duration(days: 7)))).called(1);
    });
  });

  group('schedule cards', () {
    testWidgets('show notes, the pencairan label and unknown statuses',
        (tester) async {
      answerPage1([
        _schedule(
            id: 'a',
            activity: 'pencairan',
            notes: 'Bawa kartu anggota',
            status: 'ditunda'),
      ]);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Pencairan Dana'), findsOneWidget);
      expect(find.text('Bawa kartu anggota'), findsOneWidget);
    });

    testWidgets('a start time that already passed is refused when creating',
        (tester) async {
      answerPage1(const []);
      final yesterday = today.subtract(const Duration(days: 1));
      await tester.pumpWidget(app(initialDate: yesterday));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Balai Warga');
      final submit = find.byType(ElevatedButton);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();

      expect(find.text('Waktu mulai harus di masa depan'), findsOneWidget);
      verifyNever(() => repository.createJadwal(any()));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('customer view', () {
    testWidgets('empty day can be reloaded', (tester) async {
      answerPage1(const []);
      await tester.pumpWidget(app(customerMode: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Muat Ulang'));
      await tester.pumpAndSettle();

      verify(() => repository.getJadwal(page: 1, date: today)).called(2);
    });

    testWidgets('shows the load-more footer while more pages exist',
        (tester) async {
      answerPage1([_schedule(id: 'a', status: 'diterbitkan')], hasMore: true);
      await tester.pumpWidget(app(customerMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Balai Warga'), findsOneWidget);
      expect(find.text('Coba muat lagi'), findsNothing);
    });
  });

  group('pengurus load more', () {
    testWidgets('shows progress, then a retry that appends the next page',
        (tester) async {
      tallScreen(tester);
      answerPage1([_schedule(id: 'a')], hasMore: true);
      final page2 = Completer<Either<NetworkException, JadwalPageResult>>();
      when(() => repository.getJadwal(page: 2, date: any(named: 'date')))
          .thenAnswer((_) => page2.future);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      unawaited(cubit.loadNextPage());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      page2.complete(Left(GeneralException(message: 'offline')));
      await tester.pumpAndSettle();
      expect(find.text('Coba muat lagi'), findsOneWidget);

      when(() => repository.getJadwal(page: 2, date: any(named: 'date')))
          .thenAnswer((_) async => Right(JadwalPageResult(
                items: [_schedule(id: 'b', location: 'Pos Ronda')],
                totalCount: 2,
                hasMore: false,
              )));
      await tester.tap(find.text('Coba muat lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Pos Ronda'), findsOneWidget);
      expect(find.text('Coba muat lagi'), findsNothing);
    });

    testWidgets('keeps a quiet footer while more pages are pending',
        (tester) async {
      tallScreen(tester);
      answerPage1([_schedule(id: 'a')], hasMore: true);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Balai Warga'), findsOneWidget);
    });
  });
}

JadwalEntity _schedule({
  String id = 'schedule-1',
  String location = 'Balai Warga',
  String activity = 'penimbangan',
  String notes = '',
  String status = 'draft',
}) {
  final start =
      DateUtils.dateOnly(DateTime.now()).add(const Duration(hours: 9));
  return JadwalEntity(
    id: id,
    bankSampahId: 'bank-1',
    jenisKegiatan: activity,
    mulaiPada: start,
    selesaiPada: start.add(const Duration(hours: 2)),
    lokasi: location,
    keterangan: notes,
    status: status,
  );
}
