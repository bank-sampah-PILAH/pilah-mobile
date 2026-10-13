import 'dart:typed_data';

/// A file that made it to disk: where it landed, and the folder name to say out
/// loud. [folder] is not always the directory's basename — the fallbacks below
/// live in paths no user would recognise, so they get a plain-language label.
class SavedFile {
  final String path;
  final String folder;

  /// True when the browser downloaded the file. [path] is then only its name:
  /// the page never learns where the browser put it, so there is nothing to
  /// open or share afterwards.
  final bool inBrowser;

  const SavedFile({
    required this.path,
    required this.folder,
    this.inBrowser = false,
  });
}

/// Signature of [FileDownloader.save], so callers can take a saver to test.
typedef SimpanBerkas = Future<SavedFile> Function({
  required String filename,
  required Uint8List bytes,
});
