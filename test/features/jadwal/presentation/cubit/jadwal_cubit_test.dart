import 'package:bloc_test/bloc_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
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
      when(() => repository.getJadwal())
          .thenAnswer((_) async => Right([schedule]));
      return JadwalCubit(repository);
    },
    act: (cubit) async {
      await cubit.loadJadwal();
      cubit.reset();
    },
    expect: () => [
      const JadwalLoading(),
      JadwalLoaded([schedule]),
      const JadwalInitial(),
    ],
  );

  blocTest<JadwalCubit, JadwalState>(
    'emits an error when loading schedules fails',
    build: () {
      when(() => repository.getJadwal()).thenAnswer(
        (_) async => Left(GeneralException(message: 'offline')),
      );
      return JadwalCubit(repository);
    },
    act: (cubit) => cubit.loadJadwal(),
    expect: () => [const JadwalLoading(), const JadwalError('offline')],
  );

  blocTest<JadwalCubit, JadwalState>(
    'restores the loaded schedules and returns a failed save',
    build: () {
      when(() => repository.getJadwal())
          .thenAnswer((_) async => Right([schedule]));
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
      JadwalLoaded([schedule]),
      JadwalLoaded([schedule], isSaving: true),
      JadwalLoaded([schedule]),
    ],
    verify: (_) => verify(() => repository.getJadwal()).called(1),
  );

  blocTest<JadwalCubit, JadwalState>(
    'uses update for existing schedules',
    build: () {
      final existing = _existingSchedule();
      when(() => repository.getJadwal())
          .thenAnswer((_) async => Right([existing]));
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
        JadwalLoaded([existing]),
        JadwalLoaded([existing], isSaving: true),
        JadwalLoaded([existing]),
      ];
    },
    verify: (_) {
      verify(() => repository.updateJadwal(_existingSchedule())).called(1);
      verifyNever(() => repository.createJadwal(any()));
    },
  );

  blocTest<JadwalCubit, JadwalState>(
    'returns a failed status transition without reloading',
    build: () {
      when(() => repository.transition('schedule-1', 'terbitkan')).thenAnswer(
        (_) async => Left(GeneralException(message: 'rejected')),
      );
      return JadwalCubit(repository);
    },
    act: (cubit) async => expect(
      await cubit.changeStatus('schedule-1', 'terbitkan'),
      isA<GeneralException>(),
    ),
    expect: () => [],
    verify: (_) => verifyNever(() => repository.getJadwal()),
  );

  blocTest<JadwalCubit, JadwalState>(
    'reloads after a successful status transition',
    build: () {
      when(() => repository.transition('schedule-1', 'terbitkan'))
          .thenAnswer((_) async => Right(schedule));
      when(() => repository.getJadwal())
          .thenAnswer((_) async => Right([schedule]));
      return JadwalCubit(repository);
    },
    act: (cubit) => cubit.changeStatus('schedule-1', 'terbitkan'),
    expect: () => [
      const JadwalLoading(),
      JadwalLoaded([schedule]),
    ],
    verify: (_) => verify(() => repository.getJadwal()).called(1),
  );

  blocTest<JadwalCubit, JadwalState>(
    'loads schedules and reloads after creating one',
    build: () {
      when(() => repository.getJadwal())
          .thenAnswer((_) async => Right([schedule]));
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
      JadwalLoaded([schedule]),
      JadwalLoaded([schedule], isSaving: true),
      JadwalLoaded([schedule]),
    ],
    verify: (_) {
      verify(() => repository.createJadwal(schedule)).called(1);
      verify(() => repository.getJadwal()).called(2);
    },
  );
}

JadwalEntity _existingSchedule() => JadwalEntity(
      id: 'schedule-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime.utc(2026, 10, 10, 1),
      selesaiPada: DateTime.utc(2026, 10, 10, 3),
      lokasi: 'Balai Warga',
    );
