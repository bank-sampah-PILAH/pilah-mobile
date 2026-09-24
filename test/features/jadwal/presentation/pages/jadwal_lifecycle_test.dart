import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';

class _MockJadwalCubit extends MockCubit<JadwalState> implements JadwalCubit {}

void main() {
  testWidgets('draft schedule can be published from the management list',
      (tester) async {
    final cubit = _MockJadwalCubit();
    final schedule = JadwalEntity(
      id: 'jadwal-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime.now().add(const Duration(days: 1)),
      selesaiPada: DateTime.now().add(const Duration(days: 1, hours: 2)),
      lokasi: 'Balai Warga',
    );
    when(() => cubit.state).thenReturn(JadwalLoaded([schedule]));
    when(() => cubit.loadJadwal()).thenAnswer((_) async {});
    when(() => cubit.changeStatus(any(), any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Terbitkan'), findsOneWidget);
    await tester.tap(find.text('Terbitkan'));
    await tester.pump();

    verify(() => cubit.changeStatus('jadwal-1', 'terbitkan')).called(1);
  });

  testWidgets('draft schedule confirms cancellation before transitioning',
      (tester) async {
    final cubit = _MockJadwalCubit();
    when(() => cubit.state)
        .thenReturn(JadwalLoaded([_schedule(status: 'draft')]));
    when(() => cubit.loadJadwal()).thenAnswer((_) async {});
    when(() => cubit.changeStatus(any(), any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    verifyNever(() => cubit.changeStatus(any(), any()));

    await tester.tap(find.text('Ya, batalkan'));
    await tester.pumpAndSettle();

    verify(() => cubit.changeStatus('jadwal-1', 'batalkan')).called(1);
  });

  testWidgets('published schedule confirms cancellation and reports failures',
      (tester) async {
    final cubit = _MockJadwalCubit();
    final schedule = _schedule(status: 'diterbitkan');
    when(() => cubit.state).thenReturn(JadwalLoaded([schedule]));
    when(() => cubit.loadJadwal()).thenAnswer((_) async {});
    when(() => cubit.changeStatus(any(), any())).thenAnswer(
      (_) async => GeneralException(message: 'offline'),
    );

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Batalkan'), findsOneWidget);
    expect(find.text('Tandai Selesai'), findsOneWidget);
    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Ya, batalkan'), findsOneWidget);
    verifyNever(() => cubit.changeStatus(any(), any()));

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    verifyNever(() => cubit.changeStatus(any(), any()));

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, batalkan'));
    await tester.pumpAndSettle();

    verify(() => cubit.changeStatus('jadwal-1', 'batalkan')).called(1);
    expect(find.text('offline'), findsOneWidget);
  });

  testWidgets('published schedule can be marked complete', (tester) async {
    final cubit = _MockJadwalCubit();
    final schedule = _schedule(status: 'diterbitkan');
    when(() => cubit.state).thenReturn(JadwalLoaded([schedule]));
    when(() => cubit.loadJadwal()).thenAnswer((_) async {});
    when(() => cubit.changeStatus(any(), any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Tandai Selesai'));
    await tester.pump();

    verify(() => cubit.changeStatus('jadwal-1', 'selesaikan')).called(1);
  });

  testWidgets('disables lifecycle actions during a pending transition',
      (tester) async {
    final repository = _MockJadwalRepository();
    final schedule = _schedule(status: 'draft');
    final transition = Completer<Either<NetworkException, JadwalEntity>>();
    when(() => repository.getJadwal())
        .thenAnswer((_) async => Right([schedule]));
    when(() => repository.transition('jadwal-1', 'terbitkan'))
        .thenAnswer((_) => transition.future);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terbitkan'));
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Terbitkan'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Batalkan'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Terbitkan'), warnIfMissed: false);
    verify(() => repository.transition('jadwal-1', 'terbitkan')).called(1);

    transition.complete(Right(schedule));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Terbitkan'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('disables lifecycle actions while a schedule save is pending',
      (tester) async {
    final repository = _MockJadwalRepository();
    final schedule = _schedule(status: 'draft');
    final save = Completer<Either<NetworkException, JadwalEntity>>();
    when(() => repository.getJadwal())
        .thenAnswer((_) async => Right([schedule]));
    when(() => repository.updateJadwal(schedule))
        .thenAnswer((_) => save.future);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();

    final saveResult = cubit.saveJadwal(schedule);
    await tester.pumpAndSettle();

    expect(cubit.state, JadwalLoaded([schedule], isSaving: true));
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Terbitkan'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Batalkan'))
          .onPressed,
      isNull,
    );

    save.complete(Right(schedule));
    expect(await saveResult, isNull);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Terbitkan'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('prevents opening a schedule form during a transition',
      (tester) async {
    final repository = _MockJadwalRepository();
    final schedule = _schedule(status: 'draft');
    final transition = Completer<Either<NetworkException, JadwalEntity>>();
    when(() => repository.getJadwal())
        .thenAnswer((_) async => Right([schedule]));
    when(() => repository.transition('jadwal-1', 'terbitkan'))
        .thenAnswer((_) => transition.future);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terbitkan'));
    await tester.pump();

    final fabFinder = find.byType(FloatingActionButton);
    expect(tester.widget<FloatingActionButton>(fabFinder).onPressed, isNull);
    await tester.tap(fabFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Buat Jadwal'), findsNothing);

    transition.complete(Right(schedule));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FloatingActionButton>(fabFinder).onPressed,
      isNotNull,
    );
  });
}

class _MockJadwalRepository extends Mock implements JadwalRepository {}

JadwalEntity _schedule({required String status}) => JadwalEntity(
      id: 'jadwal-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime.utc(2026, 10, 10, 1),
      selesaiPada: DateTime.utc(2026, 10, 10, 3),
      lokasi: 'Balai Warga',
      status: status,
    );
