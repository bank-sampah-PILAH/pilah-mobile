@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/file_downloader.dart';
import 'package:pilah_mobile/core/utils/report_file_action.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:web/web.dart' as web;

import 'support/pump_app.dart';

class _Share extends SharePlatform with MockPlatformInterfaceMixin {
  final calls = <ShareParams>[];

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    return const ShareResult('', ShareResultStatus.success);
  }
}

final _share = _Share();

void main() {
  final bytes = Uint8List.fromList([80, 75, 3, 4]);
  final downloads = <(String, String)>[];
  late JSFunction listener;

  setUp(() {
    downloads.clear();
    _share.calls.clear();
    SharePlatform.instance = _share;
    listener = ((web.Event event) {
      final target = event.target;
      if (target == null) return;
      final element = target as web.Element;
      if (element.tagName != 'A') return;
      final anchor = element as web.HTMLAnchorElement;
      if (anchor.download.isNotEmpty) {
        downloads.add((anchor.download, anchor.href));
      }
    }).toJS;
    web.document.addEventListener('click', listener, true.toJS);
  });

  tearDown(
      () => web.document.removeEventListener('click', listener, true.toJS));

  test('real browser save starts a named blob download and removes its anchor',
      () async {
    await FileDownloader.save(filename: 'laporan.xlsx', bytes: bytes);
    expect(downloads, hasLength(1));
    expect(downloads.single.$1, 'laporan.xlsx');
    expect(downloads.single.$2, startsWith('blob:'));
    expect(web.document.querySelector('a[download="laporan.xlsx"]'), isNull);
  });

  test('corner: repeated exports create independent browser downloads',
      () async {
    await FileDownloader.save(filename: 'laporan.xlsx', bytes: bytes);
    await FileDownloader.save(filename: 'laporan.xlsx', bytes: bytes);
    expect(downloads.map((download) => download.$1),
        ['laporan.xlsx', 'laporan.xlsx']);
    expect(downloads.map((download) => download.$2).toSet(), hasLength(2));
  });

  testWidgets(
      'download success offers Bagikan with readable bytes and XLSX metadata',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => saveReportFile(context,
                          filename: 'laporan.xlsx',
                          bytes: bytes,
                          successMessage: (folder) =>
                              'Laporan disimpan: $folder',
                          shareText: 'Laporan Operasional PILAH'),
                      child: const Text('Unduh')),
                ))));
    await tester.tap(find.text('Unduh'));
    await pumpUntilFound(tester, find.text('Bagikan'));
    expect(find.text('Bagikan'), findsOneWidget);
    expect(find.text('Gagal Menyimpan'), findsNothing);
    expect(downloads.single.$1, 'laporan.xlsx');
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Bagikan'));
    await pumpToast(tester);
    expect(_share.calls, hasLength(1));
    final file = _share.calls.single.files!.single;
    expect(file.name, 'laporan.xlsx');
    expect(file.mimeType,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    // Web XFile reads its Blob through a real FileReader event. Awaiting it
    // inside the widget test's fake-async zone leaves that event pending.
    final sharedBytes = await tester
        .runAsync(() => file.readAsBytes().timeout(const Duration(seconds: 5)));
    expect(sharedBytes, bytes);
    await settleToasts(tester);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
