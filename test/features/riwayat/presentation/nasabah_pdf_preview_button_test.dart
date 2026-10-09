import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_button.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_page.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';
import 'package:pilah_mobile/features/statement/domain/use_cases/statement_use_cases.dart';
import 'package:pilah_mobile/features/statement/presentation/blocs/statement_export_cubit.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../support/pump_app.dart';

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

  testWidgets(
      'a failed export keeps the app on the screen with an error '
      'toast, and pushes no preview', (tester) async {
    // A real delay, not an instantly-resolved future: the loading route must
    // finish its entrance animation before dismiss pops it, or the pop lands
    // mid-push (the navigator lock race the button itself works around).
    when(() => useCases.exportPdf('member-b')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return Left(NetworkException(message: 'kesalahan server'));
    });
    await pumpButton(tester);

    await tester.tap(find.byType(NasabahPdfPreviewButton));
    await pumpUntilFound(tester, find.textContaining('kesalahan server'));

    expect(find.byType(NasabahPdfPreviewPage), findsNothing);
    expect(find.text('Gagal'), findsOneWidget);
    expect(find.textContaining('kesalahan server'), findsOneWidget);

    await settleToasts(tester);
  });
}
