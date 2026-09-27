import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_model.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_page_model.dart';
import 'package:pilah_mobile/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';

class _MockJadwalRemoteDataSource extends Mock
    implements JadwalRemoteDataSource {}

void main() {
  setUpAll(() => registerFallbackValue(_schedule()));

  late _MockJadwalRemoteDataSource remote;
  late JadwalRepositoryImpl repository;

  setUp(() {
    remote = _MockJadwalRemoteDataSource();
    repository = JadwalRepositoryImpl(remote);
  });

  test('returns schedules from the remote source', () async {
    when(() => remote.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => JadwalPageModel(
        items: [_schedule()],
        totalCount: 1,
        hasMore: false,
      ),
    );

    final result = await repository.getJadwal(page: 1);

    expect(result.isRight(), isTrue);
    expect(
        result
            .getOrElse(() => const JadwalPageResult(
                  items: [],
                  totalCount: 0,
                  hasMore: false,
                ))
            .items
            .single
            .id,
        'schedule-1');
  });

  test('converts schedule-load exceptions to NetworkException', () async {
    when(() => remote.getJadwal(page: 1, date: null))
        .thenThrow(Exception('offline'));

    final result = await repository.getJadwal(page: 1);

    expect(result.fold((failure) => failure, (_) => null),
        isA<GeneralException>());
  });

  test('returns calendar markers from the remote source', () async {
    when(() => remote.getCalendarDates(
            DateTime(2026, 10, 1), DateTime(2026, 10, 31)))
        .thenAnswer((_) async => {DateTime(2026, 10, 10)});

    final result = await repository.getCalendarDates(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 31),
    );

    expect(result.getOrElse(() => const {}), {DateTime(2026, 10, 10)});
  });

  test('creates a schedule through the remote source', () async {
    when(() => remote.createJadwal(any())).thenAnswer((_) async => _schedule());

    final result = await repository.createJadwal(_schedule());

    expect(result.isRight(), isTrue);
    verify(() => remote.createJadwal(any())).called(1);
  });

  test('converts schedule-create exceptions to NetworkException', () async {
    when(() => remote.createJadwal(any())).thenThrow(Exception('offline'));

    final result = await repository.createJadwal(_schedule());

    expect(result.fold((failure) => failure, (_) => null),
        isA<GeneralException>());
  });

  test('updates a schedule through the remote source', () async {
    when(() => remote.updateJadwal(any())).thenAnswer((_) async => _schedule());

    final result = await repository.updateJadwal(_schedule());

    expect(result.isRight(), isTrue);
    verify(() => remote.updateJadwal(any())).called(1);
  });

  test('converts schedule-update exceptions to NetworkException', () async {
    when(() => remote.updateJadwal(any())).thenThrow(Exception('offline'));

    final result = await repository.updateJadwal(_schedule());

    expect(result.fold((failure) => failure, (_) => null),
        isA<GeneralException>());
  });

  test('transitions a schedule through the remote source', () async {
    when(() => remote.transition('schedule-1', 'terbitkan'))
        .thenAnswer((_) async => _schedule());

    final result = await repository.transition('schedule-1', 'terbitkan');

    expect(result.isRight(), isTrue);
    verify(() => remote.transition('schedule-1', 'terbitkan')).called(1);
  });

  test('converts transition exceptions to NetworkException', () async {
    when(() => remote.transition('schedule-1', 'terbitkan'))
        .thenThrow(Exception('offline'));

    final result = await repository.transition('schedule-1', 'terbitkan');

    expect(result.fold((failure) => failure, (_) => null),
        isA<GeneralException>());
  });
}

JadwalModel _schedule() => JadwalModel(
      id: 'schedule-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime.utc(2026, 10, 10, 1),
      selesaiPada: DateTime.utc(2026, 10, 10, 3),
      lokasi: 'Balai Warga',
    );
