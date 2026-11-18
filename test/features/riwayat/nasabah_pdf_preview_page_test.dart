import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pilah_mobile/core/analytics/replay_masks.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_page.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';

import '../../support/platform_fakes.dart';
import '../../support/pump_app.dart';

/// Whether the former file-based viewer left [filename] in a temp directory.
/// Parallel test files share /tmp, so the check is by this test's own name.
bool _leftTempCopy(String filename) => Directory.systemTemp
    .listSync()
    .whereType<Directory>()
    .where((d) => d.path.contains('riwayat_pdf'))
    .any((d) => File('${d.path}/$filename').existsSync());

void main() {
  // A minimal but structurally valid PDF, so the viewer's document load has
  // something to open.
  final pdfBytes = <int>[
    0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34, 0x0a, // %PDF-1.4
    ...utf8.encode("%test-${DateTime.now().microsecondsSinceEpoch}\n"),
  ];
  final export =
      StatementExport(bytes: pdfBytes, filename: 'Riwayat_Aktivitas_NSB-1.pdf');

  Future<void> pumpPreview(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: NasabahPdfPreviewPage(export: export)),
    );
    // The viewer starts loading the document.
    await tester.pump();
  }

  testWidgets('the statement is hidden in the screen recording',
      (tester) async {
    await pumpPreview(tester);

    // The viewer draws names and amounts on a canvas that the text masks do
    // not reach, so the whole viewer sits under HideInReplay.
    expect(
      find.descendant(
        of: find.byType(HideInReplay),
        matching: find.byType(PdfViewer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('preview page shows the filename and the download action',
      (tester) async {
    await pumpPreview(tester);

    expect(find.text('Riwayat_Aktivitas_NSB-1.pdf'), findsOneWidget);
    expect(find.byTooltip('Unduh'), findsOneWidget);
  });

  testWidgets('the viewer renders the bytes from memory, named by the file',
      (tester) async {
    await pumpPreview(tester);

    final ref = tester.widget<PdfViewer>(find.byType(PdfViewer)).documentRef;
    expect(ref, isA<PdfDocumentRefData>());
    expect((ref as PdfDocumentRefData).data, pdfBytes);
    expect(ref.key.sourceName, 'Riwayat_Aktivitas_NSB-1.pdf');
  });

  testWidgets('previewing never writes the financial PDF to disk',
      (tester) async {
    installFakePathProvider(downloads: 'Downloads', temporary: 'tmp');
    final unique = 'no-disk-${DateTime.now().microsecondsSinceEpoch}.pdf';
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: NasabahPdfPreviewPage(
          export: StatementExport(bytes: pdfBytes, filename: unique)),
    ));
    await pumpReal(tester);

    expect(_leftTempCopy(unique), isFalse,
        reason: 'no temp file: dart:io is unavailable on web and a copy '
            'of the statement would outlive the preview on native');
  });

  testWidgets('a supplied viewer replaces the pdfrx viewer', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: NasabahPdfPreviewPage(
          export: export, viewer: const Text('fake viewer')),
    ));

    expect(find.text('fake viewer'), findsOneWidget);
    expect(find.byType(PdfViewer), findsNothing);
  });

  testWidgets(
      'the Unduh button saves a durable copy into the downloads '
      'folder', (tester) async {
    final paths =
        installFakePathProvider(downloads: 'Downloads', temporary: 'tmp');
    installFakeSharePlatform();
    await pumpPreview(tester);

    expect(
      File('${paths.downloads}/Riwayat_Aktivitas_NSB-1.pdf').existsSync(),
      isFalse,
    );
    await tester.tap(find.byTooltip('Unduh'));
    // The save does real file I/O (fake-async cannot advance it) and the
    // toast rises after it — pump in the interleaved runAsync/pump steps
    // pumpUntilFound offers.
    await pumpUntilFound(tester, find.textContaining('tersimpan di folder'));

    expect(
      File('${paths.downloads}/Riwayat_Aktivitas_NSB-1.pdf').existsSync(),
      isTrue,
      reason: 'the download writes its own copy, from memory, every time',
    );
    expect(find.textContaining('Laporan PDF tersimpan di folder Download'),
        findsOneWidget);
  });
}
