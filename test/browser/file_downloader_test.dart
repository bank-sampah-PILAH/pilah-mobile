@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:pilah_mobile/core/utils/file_downloader.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  final downloads = <(String, String)>[];
  final responses = <Future<web.Response>>[];
  late JSFunction listener;

  setUp(() {
    downloads.clear();
    responses.clear();
    listener = ((web.Event event) {
      final target = event.target;
      if (target == null || (target as web.Element).tagName != 'A') return;
      final anchor = target as web.HTMLAnchorElement;
      downloads.add((anchor.download, anchor.href));
      responses.add(web.window.fetch(anchor.href.toJS).toDart);
      // Observe the real download without leaving files in the CI runner.
      event.preventDefault();
    }).toJS;
    web.document.addEventListener('click', listener, true.toJS);
  });

  tearDown(() {
    web.document.removeEventListener('click', listener, true.toJS);
  });

  test('positive: browser exports a named file and releases download resources',
      () async {
    final saved = await FileDownloader.save(
        filename: 'laporan.xlsx', bytes: Uint8List.fromList([80, 75, 3, 4]));

    expect(downloads.single.$1, 'laporan.xlsx');
    expect(downloads.single.$2, startsWith('blob:'));
    expect(saved.isBrowserDownload, isTrue);
    expect(saved.path, isEmpty);
    expect(saved.folder, 'Unduhan browser');
    expect(web.document.querySelector('a[download="laporan.xlsx"]'), isNull);
    final response = await responses.single;
    expect(response.headers.get('content-type'),
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final buffer = await response.arrayBuffer().toDart;
    expect(buffer.toDart.asUint8List(), [80, 75, 3, 4]);
    // A revoked URL cannot expose a stale report after the download starts.
    await expectLater(
        web.window.fetch(downloads.single.$2.toJS).toDart, throwsA(anything));
  });

  test('negative: a document without a body rejects the export', () async {
    final body = web.document.body!;
    body.remove();
    try {
      await expectLater(
          FileDownloader.save(filename: 'laporan.xlsx', bytes: Uint8List(0)),
          throwsA(isA<StateError>().having((error) => error.message, 'message',
              'Halaman belum siap untuk mengunduh')));
      expect(downloads, isEmpty);
    } finally {
      web.document.documentElement!.appendChild(body);
    }
  });

  test('corner: repeated empty exports keep filenames and use separate URLs',
      () async {
    for (var index = 0; index < 2; index++) {
      await FileDownloader.save(
          filename: 'Laporan bank – Oktober.xlsx', bytes: Uint8List(0));
    }
    expect(downloads.map((download) => download.$1),
        everyElement('Laporan bank – Oktober.xlsx'));
    expect(downloads.map((download) => download.$2).toSet(), hasLength(2));
    expect(web.document.querySelectorAll('a[download]').length, 0);
    for (final pending in responses) {
      final response = await pending;
      final buffer = await response.arrayBuffer().toDart;
      expect(buffer.toDart.lengthInBytes, 0);
    }
  });
}
