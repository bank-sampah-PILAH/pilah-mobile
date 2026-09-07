import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// A file that made it to disk: where it landed, and the folder name to say out
/// loud. [folder] is not always the directory's basename — the fallbacks below
/// live in paths no user would recognise, so they get a plain-language label.
class SavedFile {
  final String path;
  final String folder;

  const SavedFile({required this.path, required this.folder});
}

/// Writes generated files somewhere the user can actually find them again.
///
/// Deliberately not `file_saver`: its Android implementation writes to
/// `getExternalFilesDir(null)` — `Android/data/<package>/files` — which file
/// managers stopped showing in Android 11. Same for path_provider's
/// `getExternalStorageDirectory`. Neither satisfies "open it from the Files
/// app", which is the only reason this class exists.
///
/// The public `Download` directory needs no permission from Android 11 on: the
/// FUSE layer routes plain file writes there through MediaStore, and creating
/// your own file is always allowed. Below that it fails, which is what the
/// fallback chain in [save] is for — an app-private copy the user can still
/// share beats a failed export.
class FileDownloader {
  const FileDownloader._();

  /// Bridges to `MediaScannerConnection` in MainActivity.kt. Writing the file
  /// is only half the job on Android — see the comment there.
  static const MethodChannel _mediaScanner =
      MethodChannel('com.mobile.pilahapp/media_scanner');

  /// Tried in order. `/storage/emulated/0` is the documented location, but
  /// enough OEMs symlink `/sdcard` (and enough locales pluralise the folder)
  /// that probing is cheaper than guessing.
  static const List<String> _androidDownloadPaths = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/sdcard/Download',
  ];

  /// Writes [bytes] as [filename], returning where it went.
  ///
  /// Throws [FileSystemException] only if every candidate directory refused the
  /// write.
  static Future<SavedFile> save({
    required String filename,
    required Uint8List bytes,
  }) async {
    Object? lastError;

    for (final candidate in await _candidates()) {
      try {
        final dir = candidate.directory;
        if (!await dir.exists()) await dir.create(recursive: true);
        final file = File(_unusedPath(dir.path, filename));
        await file.writeAsBytes(bytes, flush: true);
        await _index(file.path);
        return SavedFile(path: file.path, folder: candidate.label);
      } catch (e) {
        lastError = e;
      }
    }

    throw FileSystemException(
      'Tidak ada folder yang bisa ditulis untuk menyimpan file'
      '${lastError == null ? '' : ' ($lastError)'}',
      filename,
    );
  }

  /// Announces a freshly written file to Android's MediaStore, so file managers
  /// can see it.
  ///
  /// The type is left for the scanner to infer from the extension rather than
  /// passed in — see MainActivity.kt for why that distinction decides whether
  /// the file shows up at all.
  ///
  /// Best-effort on purpose: the file is already safely on disk and shareable
  /// by the time this runs, so a missing channel — an older build, or any
  /// non-Android platform, where none of this applies — must not turn a
  /// successful save into a failed one.
  static Future<void> _index(String path) async {
    if (!Platform.isAndroid) return;
    try {
      await _mediaScanner.invokeMethod<void>('scan', {'path': path});
    } catch (e) {
      debugPrint('FileDownloader: MediaStore scan failed for $path ($e)');
    }
  }

  /// Every directory worth attempting on this platform, best first.
  static Future<List<_Candidate>> _candidates() async {
    final candidates = <_Candidate>[];

    if (Platform.isAndroid) {
      // Existing directories first: on a stock device exactly one of these is
      // real, and creating the others would scatter empty folders around
      // storage. The non-existing ones stay in the list anyway, one rung down,
      // in case the user has cleared Download entirely.
      final downloads = _androidDownloadPaths.map(Directory.new).toList();
      for (final dir in downloads.where((d) => d.existsSync())) {
        candidates.add(_Candidate(dir, 'Download'));
      }
      for (final dir in downloads.where((d) => !d.existsSync())) {
        candidates.add(_Candidate(dir, 'Download'));
      }
      candidates.addAll(
          _maybe(await getExternalStorageDirectory(), 'Dokumen Aplikasi'));
    } else if (Platform.isIOS) {
      // Surfaced in the Files app under "On My iPhone › Pilah Mobile", which
      // the UIFileSharingEnabled / LSSupportsOpeningDocumentsInPlace pair in
      // ios/Runner/Info.plist is what enables.
      candidates.add(_Candidate(
          await getApplicationDocumentsDirectory(), 'Dokumen Aplikasi'));
    } else {
      candidates.addAll(_maybe(await getDownloadsDirectory(), 'Download'));
    }

    // Always last, and always present: the one directory every platform grants.
    candidates.add(_Candidate(
        await getApplicationDocumentsDirectory(), 'Dokumen Aplikasi'));
    return candidates;
  }

  static Iterable<_Candidate> _maybe(Directory? dir, String label) =>
      dir == null ? const [] : [_Candidate(dir, label)];

  /// A path in [dirPath] that nothing occupies yet, suffixing the stem the way
  /// browsers do: `laporan.xlsx`, `laporan (1).xlsx`, `laporan (2).xlsx`.
  ///
  /// Re-exporting shouldn't quietly overwrite the copy the user already opened,
  /// and the server stamps its filenames with a timestamp anyway — a collision
  /// means two exports inside the same millisecond, so the loop stays short.
  static String _unusedPath(String dirPath, String filename) {
    final dot = filename.lastIndexOf('.');
    final stem = dot <= 0 ? filename : filename.substring(0, dot);
    final extension = dot <= 0 ? '' : filename.substring(dot);

    var path = '$dirPath/$filename';
    for (var i = 1; File(path).existsSync(); i++) {
      path = '$dirPath/$stem ($i)$extension';
    }
    return path;
  }
}

class _Candidate {
  final Directory directory;
  final String label;

  const _Candidate(this.directory, this.label);
}
