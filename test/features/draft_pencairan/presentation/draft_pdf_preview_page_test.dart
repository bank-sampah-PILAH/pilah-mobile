import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_pdf_preview_page.dart';

import '../../../support/platform_fakes.dart';

void main() {
  final file = DraftExport(
    bytes: Uint8List.fromList([1, 2, 3, 4]),
    filename: 'draft-pencairan.pdf',
  );

  setUp(() {
    DraftPdfPreviewPage.viewBuilder =
        (_, bytes) => Center(child: Text('halaman pdf ${bytes.length} byte'));
    addTearDown(() => DraftPdfPreviewPage.viewBuilder = null);
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(home: DraftPdfPreviewPage(file: file)),
      );

  testWidgets('shows the generated PDF under a Pratinjau PDF header',
      (tester) async {
    await pump(tester);

    expect(find.text('Pratinjau PDF'), findsOneWidget);
    expect(find.byKey(const Key('kembali')), findsOneWidget);
    expect(find.text('halaman pdf 4 byte'), findsOneWidget);
  });

  testWidgets('has Bagikan and Unduh side by side, with icons', (tester) async {
    await pump(tester);

    final bagikan = tester.getCenter(find.byKey(const Key('bagikan')));
    final unduh = tester.getCenter(find.byKey(const Key('unduh')));
    expect(bagikan.dy, unduh.dy);
    expect(bagikan.dx, lessThan(unduh.dx));
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
  });

  testWidgets('Unduh saves the file and says where it went', (tester) async {
    final paths = installFakePathProvider(downloads: 'Download');
    await pump(tester);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('unduh')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(File('${paths.downloads}/draft-pencairan.pdf').existsSync(), isTrue);
    expect(find.textContaining('Berkas disimpan'), findsOneWidget);
    // Let the toast's timers run out.
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('Bagikan hands the PDF to the share sheet', (tester) async {
    final share = installFakeSharePlatform();
    await pump(tester);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('bagikan')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    expect(share.shared, hasLength(1));
    expect(share.shared.single.fileNameOverrides, ['draft-pencairan.pdf']);
  });
}
