import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_page.dart';

void main() {
  testWidgets('preview page shows the filename and the download action',
      (tester) async {
    // The PdfViewer body needs the pdfrx platform runtime, absent under the
    // test binding — we pump only the page's own chrome and drop the viewer
    // before its document load settles.
    await tester.pumpWidget(
      const MaterialApp(
        home: NasabahPdfPreviewPage(
          export: StatementExport(
              bytes: [0x25, 0x50, 0x44, 0x46],
              filename: 'Riwayat_Aktivitas_NSB-1.pdf'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Riwayat_Aktivitas_NSB-1.pdf'), findsOneWidget);
    expect(find.byTooltip('Unduh'), findsOneWidget);
  });
}