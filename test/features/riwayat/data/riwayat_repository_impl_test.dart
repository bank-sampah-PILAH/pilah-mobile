import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/riwayat/data/datasources/riwayat_remote_data_source.dart';
import 'package:pilah_mobile/features/riwayat/data/repositories/riwayat_repository_impl.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';

class _Remote extends Mock implements RiwayatRemoteDataSource {}

void main() {
  late _Remote remote;
  late RiwayatRepositoryImpl repository;

  setUp(() {
    remote = _Remote();
    repository = RiwayatRepositoryImpl(remote);
  });

  test('history wraps the datasource page in Right', () async {
    const history = NasabahHistory([], false);
    when(() => remote.history('member-b', page: 2))
        .thenAnswer((_) async => history);

    final result = await repository.history('member-b', page: 2);
    expect((result as Right).value, same(history));
    verify(() => remote.history('member-b', page: 2)).called(1);
  });

  test('setoranDetail wraps the datasource detail in Right', () async {
    final detail = NasabahSetoranDetail(
      date: DateTime(2026, 9, 23),
      type: 'setoran',
      amount: '5000.00',
      note: '',
      balanceAfter: '15000.00',
      items: const [],
    );
    when(() => remote.setoranDetail('member-b', 't1'))
        .thenAnswer((_) async => detail);

    final result = await repository.setoranDetail('member-b', 't1');
    expect((result as Right).value, same(detail));
  });

  test('a datasource throw maps to Left(NetworkException)', () async {
    when(() => remote.history('member-b', page: 1)).thenAnswer((_) async {
      throw DioException(
        requestOptions: RequestOptions(path: '/pdf'),
        response: Response(
          requestOptions: RequestOptions(path: '/pdf'),
          statusCode: 400,
          data: {'error': 'Tidak ada data'},
        ),
      );
    });

    final result = await repository.history('member-b');
    expect(result.isLeft(), isTrue);
    expect(
      result.fold((f) => f.displayMessage, (_) => ''),
      isNotEmpty,
    );
  });
}
