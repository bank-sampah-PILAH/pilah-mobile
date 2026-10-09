import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';
import 'package:pilah_mobile/features/statement/domain/repository/statement_repository.dart';
import 'package:pilah_mobile/features/statement/domain/statement_interactor.dart';

class _Repository extends Mock implements StatementRepository {}

void main() {
  late _Repository repository;
  late StatementInteractor interactor;

  setUp(() {
    repository = _Repository();
    interactor = StatementInteractor(repository);
  });

  test('exportPdf delegates to the repository', () async {
    const export = StatementExport(bytes: [1], filename: 'x.pdf');
    when(() => repository.exportPdf('member-b'))
        .thenAnswer((_) async => Right(export));

    expect(await interactor.exportPdf('member-b'), Right(export));
    verify(() => repository.exportPdf('member-b')).called(1);
  });
}
