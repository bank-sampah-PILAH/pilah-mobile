import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';

class _MockJadwalRepository extends Mock implements JadwalRepository {}

void main() {
  final schedule = JadwalEntity(
    id: '',
    bankSampahId: 'bank-1',
    jenisKegiatan: 'penimbangan',
    mulaiPada: DateTime.utc(2026, 10, 10, 1),
    selesaiPada: DateTime.utc(2026, 10, 10, 3),
    lokasi: 'Balai Warga',
  );

  late _MockJadwalRepository repository;

  setUp(() {
    repository = _MockJadwalRepository();
    registerFallbackValue(schedule);
  });

  blocTest<JadwalCubit, JadwalState>(
    'reset clears the current schedule list',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      return JadwalCubit(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      cubit.reset();
    },
    expect: () => [
      const JadwalLoading(),
      JadwalLoaded([schedule], totalCount: 1),
      const JadwalInitial(),
    ],
  );

  blocTest<JadwalCubit, JadwalState>(
    'emits an error when loading schedules fails',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Left(GeneralException(message: 'offline')),
      );
      return JadwalCubit(repository);
    },
    act: (cubit) => cubit.loadJadwal(),
    expect: () => [const JadwalLoading(), const JadwalError('offline')],
  );

  blocTest<JadwalCubit, JadwalState>(
    'appends the next schedule page only when requested',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule], totalCount: 2, hasMore: true)),
      );
      when(() => repository.getJadwal(page: 2, date: null)).thenAnswer(
        (_) async =>
            Right(_page([_existingSchedule(id: 'schedule-2')], totalCount: 2)),
      );
      return JadwalCubit(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      await cubit.loadNextPage();
    },
    expect: () => [
      const JadwalLoading(),
      JadwalLoaded([schedule], hasMore: true, totalCount: 2),
      JadwalLoaded(
        [schedule],
        hasMore: true,
        isLoadingMore: true,
        totalCount: 2,
      ),
      JadwalLoaded(
        [schedule, _existingSchedule(id: 'schedule-2')],
        totalCount: 2,
      ),
    ],
    verify: (_) {
      verify(() => repository.getJadwal(page: 1, date: null)).called(1);
      verify(() => repository.getJadwal(page: 2, date: null)).called(1);
    },
  );

  blocTest<JadwalCubit, JadwalState>(
    'uses the selected day when loading its agenda',
    build: () {
      final selectedDate = DateTime(2026, 10, 10);
      when(() => repository.getJadwal(page: 1, date: selectedDate)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      return JadwalCubit(repository);
    },
    act: (cubit) => cubit.loadJadwal(date: DateTime(2026, 10, 10, 14)),
    expect: () => [
      JadwalLoaded(const [], isLoading: true),
      JadwalLoaded([schedule], totalCount: 1),
    ],
    verify: (_) => verify(
      () => repository.getJadwal(page: 1, date: DateTime(2026, 10, 10)),
    ).called(1),
  );

  blocTest<JadwalCubit, JadwalState>(
    'restores the loaded schedules and returns a failed save',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      when(() => repository.createJadwal(any())).thenAnswer(
        (_) async => Left(GeneralException(message: 'rejected')),
      );
      return JadwalCubit(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      expect(await cubit.saveJadwal(schedule), isA<GeneralException>());
    },
    expect: () => [
      const JadwalLoading(),
      JadwalLoaded([schedule], totalCount: 1),
      JadwalLoaded([schedule], isSaving: true, totalCount: 1),
      JadwalLoaded([schedule], totalCount: 1),
    ],
    verify: (_) =>
        verify(() => repository.getJadwal(page: 1, date: null)).called(1),
  );

  blocTest<JadwalCubit, JadwalState>(
    'uses update for existing schedules',
    build: () {
      final existing = _existingSchedule();
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([existing])),
      );
      when(() => repository.updateJadwal(existing))
          .thenAnswer((_) async => Right(existing));
      return JadwalCubit(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      await cubit.saveJadwal(_existingSchedule());
    },
    expect: () {
      final existing = _existingSchedule();
      return [
        const JadwalLoading(),
        JadwalLoaded([existing], totalCount: 1),
        JadwalLoaded([existing], isSaving: true, totalCount: 1),
        JadwalLoaded([existing], totalCount: 1),
      ];
    },
    verify: (_) {
      verify(() => repository.updateJadwal(_existingSchedule())).called(1);
      verifyNever(() => repository.createJadwal(any()));
    },
  );

  test('ignores a concurrent status transition', () async {
    final existing = _existingSchedule();
    final transitionResult =
        Completer<Either<NetworkException, JadwalEntity>>();
    when(() => repository.getJadwal(page: 1, date: null))
        .thenAnswer((_) async => Right(_page([existing])));
    when(() => repository.transition('schedule-1', 'terbitkan'))
        .thenAnswer((_) => transitionResult.future);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadJadwal();
    final first = cubit.changeStatus('schedule-1', 'terbitkan');
    await Future<void>.delayed(Duration.zero);
    final second = cubit.changeStatus('schedule-1', 'terbitkan');
    transitionResult.complete(Right(existing));

    expect(await first, isNull);
    expect(await second, isNull);
    verify(() => repository.transition('schedule-1', 'terbitkan')).called(1);
  });

  test('keeps status transitions locked during a list refresh', () async {
    final existing = _existingSchedule();
    final transitionResult =
        Completer<Either<NetworkException, JadwalEntity>>();
    when(() => repository.getJadwal(page: 1, date: null))
        .thenAnswer((_) async => Right(_page([existing])));
    when(() => repository.transition('schedule-1', 'terbitkan'))
        .thenAnswer((_) => transitionResult.future);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadJadwal();
    final first = cubit.changeStatus('schedule-1', 'terbitkan');
    await Future<void>.delayed(Duration.zero);
    await cubit.loadJadwal(silent: true);
    final stateDuringRefresh = cubit.state;
    final second = cubit.changeStatus('schedule-1', 'terbitkan');
    transitionResult.complete(Right(existing));

    expect(await first, isNull);
    expect(await second, isNull);
    expect(
      stateDuringRefresh,
      JadwalLoaded([existing], isTransitioning: true, totalCount: 1),
    );
    verify(() => repository.transition('schedule-1', 'terbitkan')).called(1);
  });

  test('keeps transition actions locked across a refresh during a save',
      () async {
    final existing = _existingSchedule();
    final saveResult = Completer<Either<NetworkException, JadwalEntity>>();
    when(() => repository.getJadwal(page: 1, date: null))
        .thenAnswer((_) async => Right(_page([existing])));
    when(() => repository.updateJadwal(existing))
        .thenAnswer((_) => saveResult.future);
    when(() => repository.transition('schedule-1', 'terbitkan'))
        .thenAnswer((_) async => Right(existing));
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadJadwal();
    final save = cubit.saveJadwal(existing);
    await Future<void>.delayed(Duration.zero);
    await cubit.loadJadwal(silent: true);
    final stateDuringRefresh = cubit.state;
    await cubit.changeStatus('schedule-1', 'terbitkan');

    saveResult.complete(Right(existing));
    expect(await save, isNull);
    expect(
      stateDuringRefresh,
      JadwalLoaded([existing], isSaving: true, totalCount: 1),
    );
    expect(cubit.state, JadwalLoaded([existing], totalCount: 1));
    verifyNever(() => repository.transition('schedule-1', 'terbitkan'));
  });

  test('preserves transition state when a failed refresh is retried', () async {
    final existing = _existingSchedule();
    final transitionResult =
        Completer<Either<NetworkException, JadwalEntity>>();
    var loadCount = 0;
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer((_) async {
      loadCount++;
      if (loadCount == 2) {
        return Left(GeneralException(message: 'offline'));
      }
      return Right(_page([existing]));
    });
    when(() => repository.transition('schedule-1', 'terbitkan'))
        .thenAnswer((_) => transitionResult.future);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadJadwal();
    final transition = cubit.changeStatus('schedule-1', 'terbitkan');
    await Future<void>.delayed(Duration.zero);
    await cubit.loadJadwal(silent: true);

    expect(cubit.state, const JadwalError('offline'));
    await cubit.loadJadwal();
    expect(
      cubit.state,
      JadwalLoaded([existing], isTransitioning: true, totalCount: 1),
    );

    await cubit.changeStatus('schedule-1', 'batalkan');
    verify(() => repository.transition('schedule-1', 'terbitkan')).called(1);

    transitionResult.complete(Right(existing));
    expect(await transition, isNull);
    expect(cubit.state, JadwalLoaded([existing], totalCount: 1));
  });

  test('rejects saves while a transition remains pending after refresh fails',
      () async {
    final existing = _existingSchedule();
    final newSchedule = _existingSchedule(id: '');
    final transitionResult =
        Completer<Either<NetworkException, JadwalEntity>>();
    var loadCount = 0;
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer((_) async {
      loadCount++;
      if (loadCount == 2) {
        return Left(GeneralException(message: 'offline'));
      }
      return Right(_page([existing]));
    });
    when(() => repository.transition('schedule-1', 'terbitkan'))
        .thenAnswer((_) => transitionResult.future);
    when(() => repository.createJadwal(newSchedule))
        .thenAnswer((_) async => Right(newSchedule));
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadJadwal();
    final transition = cubit.changeStatus('schedule-1', 'terbitkan');
    await Future<void>.delayed(Duration.zero);
    await cubit.loadJadwal(silent: true);
    expect(cubit.state, const JadwalError('offline'));

    final saveFailure = await cubit.saveJadwal(newSchedule);
    transitionResult.complete(Right(existing));
    expect(await transition, isNull);

    expect(saveFailure, isA<GeneralException>());
    verifyNever(() => repository.createJadwal(newSchedule));
    expect(cubit.state, JadwalLoaded([existing], totalCount: 1));
  });

  test('rejects saves while a transition remains pending after refresh fails',
      () async {
    final existing = _existingSchedule();
    final newSchedule = _existingSchedule(id: '');
    final transitionResult =
        Completer<Either<NetworkException, JadwalEntity>>();
    var loadCount = 0;
    when(() => repository.getJadwal()).thenAnswer((_) async {
      loadCount++;
      if (loadCount == 2) {
        return Left(GeneralException(message: 'offline'));
      }
      return Right([existing]);
    });
    when(() => repository.transition('schedule-1', 'terbitkan'))
        .thenAnswer((_) => transitionResult.future);
    when(() => repository.createJadwal(newSchedule))
        .thenAnswer((_) async => Right(newSchedule));
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadJadwal();
    final transition = cubit.changeStatus('schedule-1', 'terbitkan');
    await Future<void>.delayed(Duration.zero);
    await cubit.loadJadwal(silent: true);
    expect(cubit.state, const JadwalError('offline'));

    final saveFailure = await cubit.saveJadwal(newSchedule);
    transitionResult.complete(Right(existing));
    expect(await transition, isNull);

    expect(saveFailure, isA<GeneralException>());
    verifyNever(() => repository.createJadwal(newSchedule));
    expect(cubit.state, JadwalLoaded([existing]));
  });

  test('ignores a schedule load that finishes after session reset', () async {
    final previous = _existingSchedule();
    final current = _existingSchedule(id: 'schedule-2');
    final previousResult =
        Completer<Either<NetworkException, JadwalPageResult>>();
    var loadCount = 0;
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer((_) async {
      loadCount++;
      if (loadCount == 1) return previousResult.future;
      return Right(_page([current]));
    });
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    final previousLoad = cubit.loadJadwal();
    await Future<void>.delayed(Duration.zero);
    cubit.reset();
    await cubit.loadJadwal();
    previousResult.complete(Right(_page([previous])));
    await previousLoad;

    expect(cubit.state, JadwalLoaded([current], totalCount: 1));
  });

  test('a stale save cannot clear the new session save lock', () async {
    final previous = _existingSchedule();
    final current = _existingSchedule(id: 'schedule-2');
    final previousSaveResult =
        Completer<Either<NetworkException, JadwalEntity>>();
    final currentSaveResult =
        Completer<Either<NetworkException, JadwalEntity>>();
    var loadCount = 0;
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer((_) async {
      loadCount++;
      return Right(_page([loadCount == 1 ? previous : current]));
    });
    when(() => repository.updateJadwal(previous))
        .thenAnswer((_) => previousSaveResult.future);
    when(() => repository.updateJadwal(current))
        .thenAnswer((_) => currentSaveResult.future);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadJadwal();
    final previousSave = cubit.saveJadwal(previous);
    await Future<void>.delayed(Duration.zero);
    cubit.reset();
    await cubit.loadJadwal();
    final currentSave = cubit.saveJadwal(current);
    await Future<void>.delayed(Duration.zero);

    previousSaveResult.complete(Right(previous));
    expect(await previousSave, isNull);
    expect(
      cubit.state,
      JadwalLoaded([current], isSaving: true, totalCount: 1),
    );
    await cubit.changeStatus('schedule-2', 'terbitkan');
    verifyNever(() => repository.transition('schedule-2', 'terbitkan'));

    currentSaveResult.complete(Right(current));
    expect(await currentSave, isNull);
    expect(cubit.state, JadwalLoaded([current], totalCount: 1));
  });

  test('a refresh started before a transition cannot overwrite its reload',
      () async {
    final draft = _existingSchedule();
    final published = _existingSchedule(status: 'diterbitkan');
    final staleLoad = Completer<Either<NetworkException, JadwalPageResult>>();
    var loadCount = 0;
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer((_) {
      loadCount++;
      if (loadCount == 1) return Future.value(Right(_page([draft])));
      if (loadCount == 2) return staleLoad.future;
      return Future.value(Right(_page([published])));
    });
    when(() => repository.transition('schedule-1', 'terbitkan'))
        .thenAnswer((_) async => Right(published));
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadJadwal();
    final oldRefresh = cubit.loadJadwal(silent: true);
    await Future<void>.delayed(Duration.zero);
    await cubit.changeStatus('schedule-1', 'terbitkan');
    staleLoad.complete(Right(_page([draft])));
    await oldRefresh;

    expect(cubit.state, JadwalLoaded([published], totalCount: 1));
  });

  test('a stale transition cannot clear the new session transition', () async {
    final previous = _existingSchedule();
    final current = _existingSchedule(id: 'schedule-2');
    final previousResult = Completer<Either<NetworkException, JadwalEntity>>();
    final currentResult = Completer<Either<NetworkException, JadwalEntity>>();
    var loadCount = 0;
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer((_) async {
      loadCount++;
      return Right(_page([loadCount == 1 ? previous : current]));
    });
    when(() => repository.transition('schedule-1', 'terbitkan'))
        .thenAnswer((_) => previousResult.future);
    when(() => repository.transition('schedule-2', 'terbitkan'))
        .thenAnswer((_) => currentResult.future);
    final cubit = JadwalCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadJadwal();
    final previousTransition = cubit.changeStatus('schedule-1', 'terbitkan');
    await Future<void>.delayed(Duration.zero);
    cubit.reset();
    await cubit.loadJadwal();
    final currentTransition = cubit.changeStatus('schedule-2', 'terbitkan');
    await Future<void>.delayed(Duration.zero);

    previousResult.complete(
      Left(GeneralException(message: 'session expired')),
    );
    expect(await previousTransition, isA<GeneralException>());
    final stateAfterStaleFailure = cubit.state;
    currentResult.complete(Right(current));
    expect(await currentTransition, isNull);

    expect(
      stateAfterStaleFailure,
      JadwalLoaded([current], isTransitioning: true, totalCount: 1),
    );
    expect(cubit.state, JadwalLoaded([current], totalCount: 1));
    verify(() => repository.transition('schedule-2', 'terbitkan')).called(1);
  });

  blocTest<JadwalCubit, JadwalState>(
    'restores loaded schedules when a status transition fails',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([_existingSchedule()])),
      );
      when(() => repository.transition('schedule-1', 'terbitkan')).thenAnswer(
        (_) async => Left(GeneralException(message: 'rejected')),
      );
      return JadwalCubit(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      expect(
        await cubit.changeStatus('schedule-1', 'terbitkan'),
        isA<GeneralException>(),
      );
    },
    expect: () {
      final existing = _existingSchedule();
      return [
        const JadwalLoading(),
        JadwalLoaded([existing], totalCount: 1),
        JadwalLoaded([existing], isTransitioning: true, totalCount: 1),
        JadwalLoaded([existing], totalCount: 1),
      ];
    },
    verify: (_) => verify(() => repository.getJadwal(page: 1, date: null)).called(1),
  );

  blocTest<JadwalCubit, JadwalState>(
    'reloads after a successful status transition',
    build: () {
      when(() => repository.transition('schedule-1', 'terbitkan'))
          .thenAnswer((_) async => Right(schedule));
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      return JadwalCubit(repository);
    },
    act: (cubit) => cubit.changeStatus('schedule-1', 'terbitkan'),
    expect: () => [
      const JadwalLoading(),
      JadwalLoaded([schedule], isTransitioning: true, totalCount: 1),
      JadwalLoaded([schedule], totalCount: 1),
    ],
    verify: (_) =>
        verify(() => repository.getJadwal(page: 1, date: null)).called(1),
  );

  blocTest<JadwalCubit, JadwalState>(
    'loads schedules and reloads after creating one',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      when(() => repository.createJadwal(any()))
          .thenAnswer((_) async => Right(schedule));
      return JadwalCubit(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      await cubit.saveJadwal(schedule);
    },
    expect: () => [
      const JadwalLoading(),
      JadwalLoaded([schedule], totalCount: 1),
      JadwalLoaded([schedule], isSaving: true, totalCount: 1),
      JadwalLoaded([schedule], totalCount: 1),
    ],
    verify: (_) {
      verify(() => repository.createJadwal(schedule)).called(1);
      verify(() => repository.getJadwal(page: 1, date: null)).called(2);
    },
  );
}

JadwalPageResult _page(
  List<JadwalEntity> items, {
  int? totalCount,
  bool hasMore = false,
}) =>
    JadwalPageResult(
      items: items,
      totalCount: totalCount ?? items.length,
      hasMore: hasMore,
    );
JadwalEntity _existingSchedule({
  String id = 'schedule-1',
  String status = 'draft',
}) =>
    JadwalEntity(
      id: id,
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime.utc(2026, 10, 10, 1),
      selesaiPada: DateTime.utc(2026, 10, 10, 3),
      lokasi: 'Balai Warga',
      status: status,
    );
