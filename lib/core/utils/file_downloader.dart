import 'dart:typed_data';

import 'file_downloader_io.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart' as platform;
import 'saved_file.dart';

export 'saved_file.dart';

/// Download through the platform boundary without evaluating dart:io on web.
abstract final class FileDownloader {
  static Future<SavedFile> save(
          {required String filename, required Uint8List bytes}) =>
      platform.FileDownloader.save(filename: filename, bytes: bytes);
}
