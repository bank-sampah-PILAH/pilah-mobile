import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';
import 'package:pilah_mobile/features/statement/domain/use_cases/statement_use_cases.dart';
import 'package:pilah_mobile/features/statement/presentation/blocs/statement_export_cubit.dart';

class _UseCases extends Mock implements StatementUseCases {}

void main() {
  late _UseCases useCases;
  late StatementExportCubit cubit;

  setUp(() {
    useCases = _UseCases();
    cubit = StatementExportCubit(useCases);
  });

  const export = StatementExport(bytes: [1, 2], filename: 'x.pdf');

  test('export emits loading then loaded and returns the export', () async {
    when(() => useCases.exportPdf('member-b'))
        .thenAnswer((_) async => const Right(export));

    final result = await cubit.export('member-b');

    expect(result, same(export));
    expect(cubit.state.status, StatementExportStatus.loaded);
    expect(cubit.state.export, same(export));
  });

  test('export emits loading then failure and returns null', () async {
    when(() => useCases.exportPdf('member-b')).thenAnswer(
      (_) async => Left(NetworkException(message: 'kesalahan server')),
    );

    final result = await cubit.export('member-b');

    expect(result, isNull);
    expect(cubit.state.status, StatementExportStatus.failure);
    expect(cubit.state.error, isNotNull);
  });
}
