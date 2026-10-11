import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_page.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';

import '../../support/platform_fakes.dart';
import '../../support/pump_app.dart';

void main() {
  // A minimal but structurally valid PDF, so the viewer's document load has
  // something to open once its temp file is written.
  final pdfBytes = <int>[
    0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34, 0x0a, // %PDF-1.4
    ...utf8.encode("%test-${DateTime.now().microsecondsSinceEpoch}\n"),
  ];
  final export =
      StatementExport(bytes: pdfBytes, filename: 'Riwayat_Aktivitas_NSB-1.pdf');

  // Parallel test files also create riwayat_pdf temp dirs in /tmp; every
  // assertion looks at THIS page's copy only, identified by content.
  bool holdsThisPdf(File file) {
    final data = file.readAsBytesSync();
    return data.length == pdfBytes.length &&
        data.toString() == pdfBytes.toString();
  }

  List<Directory> previewCopies() {
    final matches = <Directory>[];
    for (final directory in Directory.systemTemp.listSync().whereType<Directory>()) {
      if (!directory.path.contains('riwayat_pdf')) continue;
      try {
        if (directory.listSync().whereType<File>().any(holdsThisPdf)) matches.add(directory);
      } on FileSystemException {
        // Other test isolates may dispose their preview between listing and reading.
      }
    }
    return matches;
  }

  Future<void> pumpPreview(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: NasabahPdfPreviewPage(export: export)),
    );
    // The viewer writes its temp copy and starts loading the document.
    await tester.pump();
  }

  testWidgets('preview page shows the filename and the download action',
      (tester) async {
    await pumpPreview(tester);

    expect(find.text('Riwayat_Aktivitas_NSB-1.pdf'), findsOneWidget);
    expect(find.byTooltip('Unduh'), findsOneWidget);
  });

  testWidgets('the viewer writes the bytes to a temp file for pdfrx',
      (tester) async {
    installFakePathProvider(downloads: 'Downloads', temporary: 'tmp');
    await pumpPreview(tester);
    await pumpReal(tester);

    final ours = previewCopies();
    expect(ours, isNotEmpty,
        reason: 'the preview copy is a disposable temp file, not the download');
    expect(ours.single.listSync().whereType<File>().first.readAsBytesSync(),
        pdfBytes);
    // Cleanup belongs to the widget: its dispose deletes the temp dir (the
    // unmount test asserts that).
  });

  testWidgets('unmounting the preview deletes its temp copy', (tester) async {
    installFakePathProvider(downloads: 'Downloads', temporary: 'tmp');
    await pumpPreview(tester);
    await pumpReal(tester);
    final ours = previewCopies();
    expect(ours.single.existsSync(), isTrue);

    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    await tester.pump();

    expect(ours.single.existsSync(), isFalse,
        reason: 'the financial PDF copy must not survive the preview session');
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
