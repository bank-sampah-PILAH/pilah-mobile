import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/utils/file_downloader.dart';
import 'package:share_plus/share_plus.dart';

/// Shared save/notification/share policy for downloaded reports.
Future<void> saveReportFile(
  BuildContext context, {
  required String filename,
  required Uint8List bytes,
  required String Function(String folder) successMessage,
  required String shareText,
}) async {
  final SavedFile saved;
  try {
    saved = await FileDownloader.save(filename: filename, bytes: bytes);
  } catch (error) {
    if (!context.mounted) return;
    AppNotification.showError(context,
        title: 'Gagal Menyimpan', message: 'Gagal menyimpan laporan: $error');
    return;
  }
  if (!context.mounted) return;
  AppNotification.showSuccess(context,
      title: 'Berhasil',
      message: successMessage(saved.folder),
      actionLabel: 'Bagikan',
      onAction: () => SharePlus.instance
          .share(ShareParams(files: [XFile(saved.path)], text: shareText)));
}
