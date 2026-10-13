// Runs in a browser only: flutter test --platform chrome <this file>.
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/file_downloader.dart';
import 'package:web/web.dart' as web;

void main() {
  test('downloads the bytes through the browser under their own name',
      () async {
    web.HTMLAnchorElement? clicked;
    final listener = (web.Event event) {
      final target = event.target;
      if (target is web.HTMLAnchorElement) {
        clicked = target;
        // Keep the test runner from actually saving a file.
        event.preventDefault();
      }
    }.toJS;
    web.document.addEventListener('click', listener, true.toJS);
    addTearDown(
        () => web.document.removeEventListener('click', listener, true.toJS));

    final saved = await FileDownloader.save(
      filename: 'draft-pencairan.pdf',
      bytes: Uint8List.fromList([37, 80, 68, 70]),
    );

    expect(clicked, isNotNull, reason: 'no download link was clicked');
    expect(clicked!.download, 'draft-pencairan.pdf');
    expect(clicked!.href, startsWith('blob:'));
    expect(clicked!.isConnected, isFalse,
        reason: 'the temporary link is removed again');
    expect(saved.inBrowser, isTrue);
    expect(saved.path, 'draft-pencairan.pdf');
    expect(saved.folder, 'Unduhan');
  });
}
