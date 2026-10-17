import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'saved_file.dart';
import 'report_file_metadata.dart';

/// Browser downloads are handed to the browser, never to native filesystem APIs.
abstract final class FileDownloader {
  static Future<SavedFile> save(
      {required String filename, required Uint8List bytes}) async {
    final body = web.document.body;
    if (body == null) throw StateError('Halaman belum siap untuk mengunduh');
    final blob = web.Blob(
        [bytes.toJS].toJS, web.BlobPropertyBag(type: reportMimeType(filename)));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';
    try {
      body.appendChild(anchor);
      anchor.click();
      // Let the browser consume the blob before releasing its object URL.
      await Future<void>.delayed(Duration.zero);
      return const SavedFile.browser();
    } finally {
      anchor.remove();
      web.URL.revokeObjectURL(url);
    }
  }
}
