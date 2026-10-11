import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/statement/data/remote/statement_remote_data_sources.dart';
import 'package:pilah_mobile/features/statement/data/statement_repository_impl.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';

class _Remote extends Mock implements StatementRemoteDataSources {}

void main() {
  late _Remote remote;
  late StatementRepositoryImpl repository;

  setUp(() {
    remote = _Remote();
    repository = StatementRepositoryImpl(remote);
  });

  test('a successful export parses to Right(StatementExport)', () async {
    const export = StatementExport(bytes: [1, 2], filename: 'x.pdf');
    when(() => remote.exportPdf('member-b')).thenAnswer((_) async => export);

    final result = await repository.exportPdf('member-b');

    expect((result as Right).value, same(export));
  });

  test('a failed export maps the datasource throw to Left(NetworkException)',
      () async {
    when(() => remote.exportPdf('member-b')).thenAnswer((_) async {
      throw DioException(
        requestOptions: RequestOptions(path: '/pdf'),
        response: Response(
          requestOptions: RequestOptions(path: '/pdf'),
          statusCode: 400,
          data: {'error': 'Tidak ada data pada periode ini'},
        ),
      );
    });

    final result = await repository.exportPdf('member-b');

    expect(result.isLeft(), isTrue);
    expect(
      result.fold((f) => f.displayMessage, (_) => ''),
      isNotEmpty,
    );
  });
}
