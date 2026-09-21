import 'package:bloc_test/bloc_test.dart';
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
    id: 'jadwal-1',
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
