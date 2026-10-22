import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';
import 'package:pilah_mobile/features/statement/domain/use_cases/statement_use_cases.dart';
import 'package:pilah_mobile/features/statement/presentation/providers/statement_export_provider.dart';
import 'package:pilah_mobile/services/di.dart';

class _UseCases extends Mock implements StatementUseCases {}

void main() {
  late _UseCases useCases;
  late ProviderContainer container;
  late StatementExportNotifier notifier;

  setUp(() {
    useCases = _UseCases();
    container = ProviderContainer(overrides: [
      statementExportProvider.overrideWith(
        () => StatementExportNotifier(useCases),
      ),
    ]);
    notifier = container.read(statementExportProvider.notifier);
  });

  tearDown(() => container.dispose());

  const export = StatementExport(bytes: [1, 2], filename: 'x.pdf');

  test('the provider resolves its use case from DI', () async {
    di.registerSingleton<StatementUseCases>(useCases);
    final defaultContainer = ProviderContainer();
    addTearDown(defaultContainer.dispose);
    addTearDown(() => di.unregister<StatementUseCases>());

    expect(defaultContainer.read(statementExportProvider),
        const StatementExportState());
  });

  test('export returns the PDF and records loaded state', () async {
    when(() => useCases.exportPdf('member-b'))
        .thenAnswer((_) async => const Right(export));
    final statuses = <StatementExportStatus>[];
    final subscription = container.listen(statementExportProvider, (_, state) {
      statuses.add(state.status);
    });

    final result = await notifier.export('member-b');
    subscription.close();

    expect(result, same(export));
    expect(container.read(statementExportProvider).status,
        StatementExportStatus.loaded);
    expect(container.read(statementExportProvider).export, same(export));
    expect(statuses,
        [StatementExportStatus.loading, StatementExportStatus.loaded]);
  });

  test('export records the typed failure and returns null', () async {
    when(() => useCases.exportPdf('member-b')).thenAnswer(
      (_) async => Left(NetworkException(message: 'kesalahan server')),
    );

    final result = await notifier.export('member-b');

    expect(result, isNull);
    expect(container.read(statementExportProvider).status,
        StatementExportStatus.failure);
    expect(container.read(statementExportProvider).error, isNotNull);
  });
}
