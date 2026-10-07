import 'dart:async';
import 'dart:io';

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

import '../../support/platform_fakes.dart';
import '../../support/pump_app.dart';

class _UseCases extends Mock implements StatementUseCases {}

const _pdf =
    StatementExport(bytes: [37, 80, 68, 70], filename: '/statement.pdf');

void main() {
  late _UseCases useCases;
  late StatementExportCubit cubit;

  setUp(() {
    useCases = _UseCases();
    cubit = StatementExportCubit(useCases);
    di.registerSingleton<StatementExportCubit>(cubit);
  });
  tearDown(() async {
    await di.unregister<StatementExportCubit>();
    await cubit.close();
  });

  Future<void> openButton(WidgetTester tester) =>
      tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: NasabahPdfPreviewButton(
                  membershipId: 'member-1',
                  previewViewer: Text('PDF content')))));

  testWidgets(
      'PDF export opens a preview and returns to history without a navigator lock',
      (tester) async {
    when(() => useCases.exportPdf('member-1')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return const Right(_pdf);
    });
    await openButton(tester);
    await tester.tap(find.byTooltip('Pratinjau PDF'));
    await tester.pump();
    expect(find.text('Menyiapkan laporan PDF...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('/statement.pdf'), findsOneWidget);
    expect(find.text('PDF content'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await settleToasts(tester);
    expect(find.byTooltip('Pratinjau PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
    verify(() => useCases.exportPdf('member-1')).called(1);
  });

  testWidgets('PDF export failure reports the typed network error',
      (tester) async {
    when(() => useCases.exportPdf('member-1')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return Left(NetworkException(message: 'PDF tidak tersedia'));
    });
    await openButton(tester);
    await tester.tap(find.byTooltip('Pratinjau PDF'));
    await pumpUntilFound(tester, find.text('PDF tidak tersedia'));
    expect(find.text('PDF tidak tersedia'), findsOneWidget);
    expect(find.byTooltip('Unduh'), findsNothing);
    await settleToasts(tester);
  });

  testWidgets(
      'leaving history during export never navigates on the disposed context',
      (tester) async {
    final pending = Completer<Either<NetworkException, StatementExport>>();
    when(() => useCases.exportPdf('member-1'))
        .thenAnswer((_) => pending.future);
    await openButton(tester);
    await tester.tap(find.byTooltip('Pratinjau PDF'));
    await tester.pump();
    await tester.pumpWidget(
        MaterialApp(key: UniqueKey(), home: const Text('Other screen')));
    pending.complete(const Right(_pdf));
    await tester.pumpAndSettle();
    expect(find.text('/statement.pdf'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  Future<void> openPage(WidgetTester tester) =>
      tester.pumpWidget(const MaterialApp(
          home: NasabahPdfPreviewPage(
              export: _pdf, viewer: Text('PDF content'))));

  testWidgets('download saves the original bytes and shares the saved PDF',
      (tester) async {
    final paths = installFakePathProvider(downloads: 'Downloads');
    final share = installFakeSharePlatform();
    await openPage(tester);
    await tester.tap(find.byTooltip('Unduh'));
    await pumpUntilFound(tester, find.textContaining('Laporan PDF tersimpan'));
    expect(find.textContaining('Laporan PDF tersimpan'), findsOneWidget);
    expect(
        File('${paths.downloads}/statement.pdf').readAsBytesSync(), _pdf.bytes);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Bagikan'));
    await pumpToast(tester);
    expect(share.shared.single.text, 'Laporan Riwayat Aktivitas PILAH');
    expect(File(share.shared.single.files!.single.path).readAsBytesSync(),
        _pdf.bytes);
    await settleToasts(tester);
  });

  testWidgets('save failure reports an error and never offers sharing',
      (tester) async {
    final paths = installFakePathProvider();
    File(paths.documents).createSync(recursive: true);
    await openPage(tester);
    await tester.tap(find.byTooltip('Unduh'));
    await pumpUntilFound(tester, find.text('Gagal Menyimpan'));
    expect(find.text('Gagal Menyimpan'), findsOneWidget);
    expect(find.text('Bagikan'), findsNothing);
    await settleToasts(tester);
  });
}
