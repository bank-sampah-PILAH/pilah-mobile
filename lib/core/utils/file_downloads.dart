/// Saves generated files (exports, reports) where the user can find them.
///
/// On a device, `file_downloader.dart` writes to the Download folder. In a
/// browser, `file_downloader_web.dart` hands the file to the browser as a
/// download. Both expose the same `FileDownloader.save`; import this file,
/// not either of them.
library;

export 'file_downloader.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart';
export 'saved_file.dart';
