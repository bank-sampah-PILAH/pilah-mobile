import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'report_file_metadata.dart';
import 'saved_file.dart';

/// Native shares use the saved path; browsers retain the actual report bytes.
XFile createReportShareFile({
  required SavedFile saved,
  required String filename,
  required Uint8List bytes,
}) =>
    saved.isBrowserDownload
        ? XFile.fromData(bytes,
            name: filename, mimeType: reportMimeType(filename))
        : XFile(saved.path);
