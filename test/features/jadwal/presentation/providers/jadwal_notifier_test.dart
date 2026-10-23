import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/states/jadwal_state.dart';

class _MockJadwalRepository extends Mock implements JadwalRepository {}

void providerTest(
  String description, {
  required JadwalNotifier Function() build,
  required FutureOr<void> Function(JadwalNotifier) act,
  List<JadwalState> Function()? expect,
  FutureOr<void> Function(JadwalNotifier)? verify,
}) {
  test(description, () async {
    final notifier = build();
    final container = ProviderContainer(overrides: [
      jadwalProvider.overrideWith(() => notifier),
    ]);
    final emitted = <JadwalState>[];
    final subscription = container.listen(
      jadwalProvider,
      (_, next) => emitted.add(next),
    );
    try {
      await act(notifier);
      if (expect != null) flutter_test.expect(emitted, equals(expect()));
      await verify?.call(notifier);
    } finally {
      subscription.close();
      container.dispose();
    }
  });
}

void main() {
  test('initial state has value equality', () {
    expect(JadwalInitial(), JadwalInitial());
  });

  final containers = <ProviderContainer>[];
  final schedule = JadwalEntity(
    id: '',
    bankSampahId: 'bank-1',
    jenisKegiatan: 'penimbangan',
    mulaiPada: DateTime.utc(2026, 10, 10, 1),
    selesaiPada: DateTime.utc(2026, 10, 10, 3),
    lokasi: 'Balai Warga',
  );

  late _MockJadwalRepository repository;

  JadwalNotifier createNotifier(JadwalRepository repository) {
    final container = ProviderContainer(overrides: [
      jadwalProvider.overrideWith(() => JadwalNotifier(repository)),
    ]);
    containers.add(container);
    return container.read(jadwalProvider.notifier);
  }

  tearDown(() {
    for (final container in containers) {
      container.dispose();
    }
    containers.clear();
  });

  setUp(() {
    repository = _MockJadwalRepository();
    registerFallbackValue(schedule);
    registerFallbackValue(DateTime(2026));
    // The upcoming-dates range is requested after every mutation; tests that
    // care about the visible month stub their own range over this default.
    when(() => repository.getCalendarDates(any(), any()))
        .thenAnswer((_) async => const Right({}));
  });

  providerTest(
    'reset clears the current schedule list',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      return JadwalNotifier(repository);
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

  group('a date range', () {
    final from = DateTime(2026, 10, 19);
    final to = DateTime(2026, 10, 31);

    void stubRange({bool hasMore = false}) {
      when(() => repository.getJadwal(page: 1, date: from, dateTo: to))
          .thenAnswer((_) async => Right(_page([schedule], hasMore: hasMore)));
      when(() => repository.getJadwal(page: 2, date: from, dateTo: to))
          .thenAnswer((_) async => Right(_page(const [])));
      when(() => repository.createJadwal(any()))
          .thenAnswer((_) async => Right(schedule));
    }

    providerTest(
      'is requested from the start date to the end date',
      build: () {
        stubRange();
        return JadwalNotifier(repository);
      },
      act: (cubit) => cubit.loadJadwal(date: from, dateTo: to),
      verify: (cubit) {
        verify(() => repository.getJadwal(page: 1, date: from, dateTo: to))
            .called(1);
        expect((cubit.state as JadwalLoaded).items, [schedule]);
      },
    );

    providerTest(
      'keeps its end date when the next page is requested',
      build: () {
        stubRange(hasMore: true);
        return JadwalNotifier(repository);
      },
      act: (cubit) async {
        await cubit.loadJadwal(date: from, dateTo: to);
        await cubit.loadNextPage();
      },
      verify: (_) => verify(
        () => repository.getJadwal(page: 2, date: from, dateTo: to),
      ).called(1),
    );

    providerTest(
      'is reloaded as a range after saving a schedule',
      build: () {
        stubRange();
        return JadwalNotifier(repository);
      },
      act: (cubit) async {
        await cubit.loadJadwal(date: from, dateTo: to);
        await cubit.saveJadwal(schedule);
      },
      verify: (_) => verify(
        () => repository.getJadwal(page: 1, date: from, dateTo: to),
      ).called(2),
    );

    providerTest(
      'moving only the end date is a new list, shown as loading',
      build: () {
        stubRange();
        when(() => repository.getJadwal(
              page: 1,
              date: from,
              dateTo: DateTime(2026, 10, 25),
            )).thenAnswer((_) async => Right(_page(const [])));
        return JadwalNotifier(repository);
      },
      act: (cubit) async {
        await cubit.loadJadwal(date: from, dateTo: to);
        await cubit.loadJadwal(date: from, dateTo: DateTime(2026, 10, 25));
      },
      verify: (cubit) => expect((cubit.state as JadwalLoaded).items, isEmpty),
    );
  });

  providerTest(
    'upcoming dates cover 90 days in ranges the server accepts (max 62 days)',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null))
          .thenAnswer((_) async => Right(_page(const [])));
      when(() => repository.getCalendarDates(any(), any())).thenAnswer(
        (invocation) async {
          final start = invocation.positionalArguments[0] as DateTime;
          return Right({
            if (start == DateTime(2026, 10, 19)) DateTime(2026, 11, 3),
            if (start != DateTime(2026, 10, 19)) DateTime(2027, 1, 5),
          });
        },
      );
      return JadwalNotifier(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      await cubit.loadUpcomingDates(today: DateTime(2026, 10, 19, 14));
    },
    verify: (cubit) {
      final ranges = verify(
        () => repository.getCalendarDates(captureAny(), captureAny()),
      ).captured;
      final starts = [for (var i = 0; i < ranges.length; i += 2) ranges[i]];
      final ends = [for (var i = 1; i < ranges.length; i += 2) ranges[i]];
      expect(starts.first, DateTime(2026, 10, 19));
      expect(ends.last, DateTime(2026, 10, 19).add(const Duration(days: 90)));
      for (var i = 0; i < starts.length; i++) {
        expect(
          (ends[i] as DateTime).difference(starts[i] as DateTime).inDays,
          lessThanOrEqualTo(62),
        );
      }
      for (var i = 1; i < starts.length; i++) {
        expect(
          (starts[i] as DateTime).difference(ends[i - 1] as DateTime).inDays,
          1,
          reason: 'ranges follow each other without a gap',
        );
      }
      expect((cubit.state as JadwalLoaded).upcomingDates, {
        DateTime(2026, 11, 3),
        DateTime(2027, 1, 5),
      });
    },
  );

  providerTest(
    'upcoming dates fetched before the list loads are kept for it',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null))
          .thenAnswer((_) async => Right(_page(const [])));
      when(() => repository.getCalendarDates(any(), any())).thenAnswer(
        (_) async => Right({DateTime(2026, 11, 3)}),
      );
      return JadwalNotifier(repository);
    },
    act: (cubit) async {
      await cubit.loadUpcomingDates(today: DateTime(2026, 10, 19));
      await cubit.loadJadwal();
    },
    verify: (cubit) => expect(
      (cubit.state as JadwalLoaded).upcomingDates,
      {DateTime(2026, 11, 3)},
    ),
  );

  var offline = false;
  providerTest(
    'a failed upcoming request leaves the earlier dates alone',
    build: () {
      offline = false;
      when(() => repository.getJadwal(page: 1, date: null))
          .thenAnswer((_) async => Right(_page(const [])));
      when(() => repository.getCalendarDates(any(), any())).thenAnswer(
        (_) async => offline
            ? Left(GeneralException(message: 'offline'))
            : Right({DateTime(2026, 11, 3)}),
      );
      return JadwalNotifier(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      await cubit.loadUpcomingDates(today: DateTime(2026, 10, 19));
      offline = true;
      await cubit.loadUpcomingDates(today: DateTime(2026, 10, 19));
    },
    verify: (cubit) => expect(
      (cubit.state as JadwalLoaded).upcomingDates,
      {DateTime(2026, 11, 3)},
    ),
  );

  providerTest(
    'saving a schedule refreshes the upcoming dates too',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null))
          .thenAnswer((_) async => Right(_page(const [])));
      when(() => repository.getCalendarDates(any(), any()))
          .thenAnswer((_) async => const Right({}));
      when(() => repository.createJadwal(any()))
          .thenAnswer((_) async => Right(schedule));
      return JadwalNotifier(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      await cubit.saveJadwal(schedule);
    },
    verify: (_) {
      final ranges = verify(
        () => repository.getCalendarDates(captureAny(), captureAny()),
      ).captured;
      final ends = [for (var i = 1; i < ranges.length; i += 2) ranges[i]];
      final starts = [for (var i = 0; i < ranges.length; i += 2) ranges[i]];
      expect(
        [
          for (var i = 0; i < starts.length; i++)
            (ends[i] as DateTime).difference(starts[i] as DateTime).inDays,
        ],
        isNotEmpty,
      );
      final today = DateUtils.dateOnly(DateTime.now());
      expect(
        ends,
        contains(today.add(const Duration(days: 90))),
        reason: 'the upcoming ranges are requested again after saving',
      );
    },
  );

  providerTest(
    'emits an error when loading schedules fails',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Left(GeneralException(message: 'offline')),
      );
      return JadwalNotifier(repository);
    },
    act: (cubit) => cubit.loadJadwal(),
    expect: () => [const JadwalLoading(), const JadwalError('offline')],
  );

  providerTest(
    'appends the next schedule page only when requested',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule], totalCount: 2, hasMore: true)),
      );
      when(() => repository.getJadwal(page: 2, date: null)).thenAnswer(
        (_) async =>
            Right(_page([_existingSchedule(id: 'schedule-2')], totalCount: 2)),
      );
      return JadwalNotifier(repository);
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

  providerTest(
    'uses the selected day when loading its agenda',
    build: () {
      final selectedDate = DateTime(2026, 10, 10);
      when(() => repository.getJadwal(page: 1, date: selectedDate)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      return JadwalNotifier(repository);
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

  providerTest(
    'restores the loaded schedules and returns a failed save',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      when(() => repository.createJadwal(any())).thenAnswer(
        (_) async => Left(GeneralException(message: 'rejected')),
      );
      return JadwalNotifier(repository);
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

  providerTest(
    'uses update for existing schedules',
    build: () {
      final existing = _existingSchedule();
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([existing])),
      );
      when(() => repository.updateJadwal(existing))
          .thenAnswer((_) async => Right(existing));
      return JadwalNotifier(repository);
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
    final cubit = createNotifier(repository);

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
    final cubit = createNotifier(repository);

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
    final cubit = createNotifier(repository);

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
    final cubit = createNotifier(repository);

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
    final cubit = createNotifier(repository);

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
    final cubit = createNotifier(repository);

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
    final cubit = createNotifier(repository);

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
    final cubit = createNotifier(repository);

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
    final cubit = createNotifier(repository);

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

  providerTest(
    'restores loaded schedules when a status transition fails',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([_existingSchedule()])),
      );
      when(() => repository.transition('schedule-1', 'terbitkan')).thenAnswer(
        (_) async => Left(GeneralException(message: 'rejected')),
      );
      return JadwalNotifier(repository);
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
    verify: (_) =>
        verify(() => repository.getJadwal(page: 1, date: null)).called(1),
  );

  providerTest(
    'reloads after a successful status transition',
    build: () {
      when(() => repository.transition('schedule-1', 'terbitkan'))
          .thenAnswer((_) async => Right(schedule));
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      return JadwalNotifier(repository);
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

  providerTest(
    'loads schedules and reloads after creating one',
    build: () {
      when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
        (_) async => Right(_page([schedule])),
      );
      when(() => repository.createJadwal(any()))
          .thenAnswer((_) async => Right(schedule));
      return JadwalNotifier(repository);
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

  test('keeps the list and reports the error when the next page fails',
      () async {
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => Right(_page([schedule], totalCount: 2, hasMore: true)),
    );
    when(() => repository.getJadwal(page: 2, date: null)).thenAnswer(
      (_) async => Left(GeneralException(message: 'offline')),
    );
    final cubit = createNotifier(repository);

    await cubit.loadJadwal();
    await cubit.loadNextPage();

    final state = cubit.state as JadwalLoaded;
    expect(state.items, [schedule]);
    expect(state.isLoadingMore, isFalse);
    expect(state.loadingMoreError, isNotNull);
  });

  test('saving before anything was loaded still creates and then lists it',
      () async {
    when(() => repository.createJadwal(any()))
        .thenAnswer((_) async => Right(schedule));
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => Right(_page([schedule])),
    );
    final cubit = createNotifier(repository);

    final error = await cubit.saveJadwal(schedule);

    expect(error, isNull);
    expect((cubit.state as JadwalLoaded).items, [schedule]);
    expect((cubit.state as JadwalLoaded).isSaving, isFalse);
  });

  test('a page result is equal to another with the same content', () {
    expect(_page([schedule], totalCount: 3, hasMore: true),
        _page([schedule], totalCount: 3, hasMore: true));
    expect(_page([schedule]), isNot(_page([schedule], hasMore: true)));
  });
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
