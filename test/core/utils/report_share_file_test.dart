import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/report_file_metadata.dart';
import 'package:pilah_mobile/core/utils/report_share_file.dart';
import 'package:pilah_mobile/core/utils/saved_file.dart';

void main() {
  final bytes = Uint8List.fromList([80, 75, 0, 255]);

  test('native sharing retains the actual saved collision-safe path', () {
    const saved =
        SavedFile(path: '/Downloads/laporan (1).xlsx', folder: 'Download');
    final file = createReportShareFile(
        saved: saved, filename: 'laporan.xlsx', bytes: bytes);
    expect(file.path, saved.path);
    expect(saved.isBrowserDownload, isFalse);
  });

  test('browser sharing preserves bytes, original filename and XLSX MIME',
      () async {
    const saved = SavedFile.browser();
    final file = createReportShareFile(
        saved: saved, filename: 'LAPORAN.XLSX', bytes: bytes);
    expect(saved.isBrowserDownload, isTrue);
    expect(saved.path, isEmpty);
    // IO cross_file has no name for pathless data. Callers set fileNameOverrides;
    // the Chrome regression verifies the browser XFile.name metadata itself.
    expect(file.mimeType,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    expect(await file.readAsBytes(), bytes);
  });

  test('PDF MIME and empty bytes are preserved for a browser attachment',
      () async {
    final file = createReportShareFile(
        saved: const SavedFile.browser(),
        filename: 'laporan.PDF',
        bytes: Uint8List(0));
    expect(file.mimeType, 'application/pdf');
    expect(await file.readAsBytes(), isEmpty);
  });

  test('unknown filename extensions use safe binary MIME, not fake Excel', () {
    expect(reportMimeType('attachment.bin'), 'application/octet-stream');
    expect(reportMimeType('README'), 'application/octet-stream');
  });
}
