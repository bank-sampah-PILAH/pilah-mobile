import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/file_downloads.dart';
import 'package:pilah_mobile/core/utils/report_export_sheet.dart';

import '../../support/pump_app.dart';

Future<void> _ekspor(WidgetTester tester, SavedFile hasil) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => saveAndOfferShare(
              context,
              filename: 'laporan.xlsx',
              bytes: const [1, 2, 3],
              successMessage: (saved) =>
                  'Laporan disimpan ke folder ${saved.folder}',
              shareText: 'Laporan PILAH',
              simpan: ({required filename, required bytes}) async => hasil,
            ),
            child: const Text('ekspor'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ekspor'));
  await pumpToast(tester);
}

void main() {
  testWidgets('a report saved on the device can be shared from the toast',
      (tester) async {
    await _ekspor(
      tester,
      const SavedFile(path: '/Download/laporan.xlsx', folder: 'Download'),
    );

    expect(find.text('Laporan disimpan ke folder Download'), findsOneWidget);
    expect(find.text('Bagikan'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets('a report the browser downloaded offers no Bagikan',
      (tester) async {
    await _ekspor(
      tester,
      const SavedFile(path: 'laporan.xlsx', folder: 'Unduhan', inBrowser: true),
    );

    expect(find.text('Laporan disimpan ke folder Unduhan'), findsOneWidget);
    expect(find.text('Bagikan'), findsNothing);
    await settleToasts(tester);
  });
}
