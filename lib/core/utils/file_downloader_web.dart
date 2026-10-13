import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'saved_file.dart';

/// Hands generated files to the browser as a download.
///
/// The browser decides where the file lands (its download folder, or wherever
/// the user picks), and the page is never told. [SavedFile.inBrowser] says so,
/// and callers leave out anything that needs the saved path, like sharing it.
class FileDownloader {
  const FileDownloader._();

  /// What the success message calls the destination: the browser's default
  /// download folder, by its Indonesian name.
  static const _folder = 'Unduhan';

  /// How long the blob URL stays alive after the click. The browser copies
  /// the data when the download starts, so this only has to outlast that.
  static const _revokeAfter = Duration(minutes: 1);

  /// Starts a download of [bytes] as [filename].
  static Future<SavedFile> save({
    required String filename,
    required Uint8List bytes,
  }) async {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: _mimeType(filename)),
    );
    final url = web.URL.createObjectURL(blob);
    final link = web.HTMLAnchorElement()
      ..href = url
      ..download = filename;
    web.document.body!.append(link);
    link.click();
    link.remove();
    Timer(_revokeAfter, () => web.URL.revokeObjectURL(url));
    return SavedFile(path: filename, folder: _folder, inBrowser: true);
  }

  static String _mimeType(String filename) {
    final name = filename.toLowerCase();
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'application/octet-stream';
  }
}
