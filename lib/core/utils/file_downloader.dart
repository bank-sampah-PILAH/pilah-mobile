/// Saves generated files (exports, reports) where the user can find them.
///
/// On a device, `file_downloader_io.dart` writes to the Download folder. In a
/// browser, `file_downloader_web.dart` hands the file to the browser as a
/// download. Both expose the same `FileDownloader.save`.
library;

export 'file_downloader_io.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart';
export 'saved_file.dart';
