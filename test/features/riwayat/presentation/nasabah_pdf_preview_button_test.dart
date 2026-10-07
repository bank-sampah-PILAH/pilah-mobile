import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_button.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_page.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';
import 'package:pilah_mobile/features/statement/domain/use_cases/statement_use_cases.dart';
import 'package:pilah_mobile/features/statement/presentation/blocs/statement_export_cubit.dart';
import 'package:pilah_mobile/services/di.dart';

class _UseCases extends Mock implements StatementUseCases {}

void main() {
  late _UseCases useCases;

  setUp(() {
    useCases = _UseCases();
    di.registerFactory<StatementExportCubit>(
        () => StatementExportCubit(useCases));
    addTearDown(() async {
      await di.unregister<StatementExportCubit>();
    });
  });

  Future<void> pumpButton(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    body: NasabahPdfPreviewButton(membershipId: 'member-b'),
                  ))),
    );
  }

  const export = StatementExport(
      bytes: [0x25, 0x50, 0x44, 0x46], filename: 'Riwayat_Aktivitas.pdf');

  testWidgets('a successful export pushes the in-app preview page',
      (tester) async {
    when(() => useCases.exportPdf('member-b'))
        .thenAnswer((_) async => const Right(export));
    await pumpButton(tester);

    await tester.tap(find.byType(NasabahPdfPreviewButton));
    await tester.pumpAndSettle();

    expect(find.byType(NasabahPdfPreviewPage), findsOneWidget);
    expect(find.text('Riwayat_Aktivitas.pdf'), findsOneWidget);
  });
}
