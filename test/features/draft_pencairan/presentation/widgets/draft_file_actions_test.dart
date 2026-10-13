import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/file_downloads.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/draft_file_actions.dart';

import '../../../../support/pump_app.dart';

final _berkas = DraftExport(
  bytes: Uint8List.fromList([1, 2, 3]),
  filename: 'draft-pencairan.pdf',
);

Future<void> _simpan(WidgetTester tester, SavedFile hasil) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => simpanBerkasDraft(
              context,
              _berkas,
              simpan: ({required filename, required bytes}) async => hasil,
            ),
            child: const Text('simpan'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('simpan'));
  await pumpToast(tester);
}

void main() {
  testWidgets('a file saved on the device can be shared from the toast',
      (tester) async {
    await _simpan(
      tester,
      const SavedFile(
          path: '/Download/draft-pencairan.pdf', folder: 'Download'),
    );

    expect(find.text('Berkas disimpan ke folder Download'), findsOneWidget);
    expect(find.text('Bagikan'), findsOneWidget);
    await settleToasts(tester);
  });

  testWidgets(
      'a file the browser downloaded offers no Bagikan, '
      'since there is no saved path to share', (tester) async {
    await _simpan(
      tester,
      const SavedFile(
        path: 'draft-pencairan.pdf',
        folder: 'Unduhan',
        inBrowser: true,
      ),
    );

    expect(find.text('Berkas disimpan ke folder Unduhan'), findsOneWidget);
    expect(find.text('Bagikan'), findsNothing);
    await settleToasts(tester);
  });
}
