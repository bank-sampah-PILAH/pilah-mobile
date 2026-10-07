import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/file_downloader.dart';

import '../../support/platform_fakes.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  test('saves into the downloads folder, creating it when missing', () async {
    final paths = installWithDownloads();

    final saved =
        await FileDownloader.save(filename: 'laporan.xlsx', bytes: bytes);

    expect(saved.folder, 'Download');
    expect(saved.path, '${paths.downloads}/laporan.xlsx');
    expect(File(saved.path).readAsBytesSync(), bytes);
  });

  test('never overwrites an earlier export', () async {
    installWithDownloads();

    final first =
        await FileDownloader.save(filename: 'laporan.xlsx', bytes: bytes);
    final second =
        await FileDownloader.save(filename: 'laporan.xlsx', bytes: bytes);
    final third =
        await FileDownloader.save(filename: 'laporan.xlsx', bytes: bytes);

    expect(first.path, endsWith('/laporan.xlsx'));
    expect(second.path, endsWith('/laporan (1).xlsx'));
    expect(third.path, endsWith('/laporan (2).xlsx'));
  });

  test('a name without an extension is suffixed at the end', () async {
    installWithDownloads();

    await FileDownloader.save(filename: 'laporan', bytes: bytes);
    final second = await FileDownloader.save(filename: 'laporan', bytes: bytes);

    expect(second.path, endsWith('/laporan (1)'));
  });

  test('falls back to the documents folder without a downloads folder',
      () async {
    final paths = installFakePathProvider();

    final saved = await FileDownloader.save(filename: 'a.xlsx', bytes: bytes);

    expect(saved.folder, 'Dokumen Aplikasi');
    expect(saved.path, '${paths.documents}/a.xlsx');
  });

  test('falls back when the downloads folder cannot be written', () async {
    final paths = installFakePathProvider(downloads: 'blocked/Download');
    // A plain file where the downloads folder's parent should be.
    final blocked = File(paths.downloads!.replaceFirst('/Download', ''))
      ..createSync(recursive: true);
    expect(blocked.existsSync(), isTrue);

    final saved = await FileDownloader.save(filename: 'a.xlsx', bytes: bytes);

    expect(saved.folder, 'Dokumen Aplikasi');
  });

  test('throws once every folder has refused', () async {
    final paths = installFakePathProvider();
    // The documents path is a file, so it can be neither created nor written.
    File(paths.documents).createSync(recursive: true);

    await expectLater(
      FileDownloader.save(filename: 'a.xlsx', bytes: bytes),
      throwsA(isA<FileSystemException>()
          .having((e) => e.message, 'message', contains('Tidak ada folder'))),
    );
  });
}

FakePathProvider installWithDownloads() =>
    installFakePathProvider(downloads: 'Downloads');
