import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'file_downloader.dart';
import '../bases/widgets/app_notification.dart';

/// The save-then-share confirmation shared by every report export
/// (transaksi XLSX, riwayat PDF): saves [bytes] as [filename], shows a
/// success toast with a "Bagikan" action, or the error toast on failure.
///
/// Extracted from duplicated copies in the two export flows — sharing used
/// to be the only outcome: the file went to the cache directory and the
/// system share sheet opened over it, so a user who just wanted the file on
/// their phone had to mail it to themselves. Saving to Download and putting
/// "Bagikan" on the confirmation covers both, and asks nothing of the
/// majority who only wanted the file. share_plus copies whatever path it is
/// handed into its own cache before handing out a content:// URI, so the
/// saved file is shareable straight from Download — no second copy to keep
/// in sync.
Future<void> saveAndOfferShare(
  BuildContext context, {
  required String filename,
  required List<int> bytes,
  required String Function(SavedFile saved) successMessage,
  required String shareText,
}) async {
  final SavedFile saved;
  try {
    saved = await FileDownloader.save(
      filename: filename,
      bytes: Uint8List.fromList(bytes),
    );
  } catch (e) {
    if (!context.mounted) return;
    AppNotification.showError(
      context,
      title: 'Gagal Menyimpan',
      message: 'Gagal menyimpan laporan: $e',
    );
    return;
  }
  if (!context.mounted) return;
  AppNotification.showSuccess(
    context,
    title: 'Berhasil',
    message: successMessage(saved),
    actionLabel: 'Bagikan',
    onAction: () => SharePlus.instance.share(
      ShareParams(
        files: [XFile(saved.path)],
        text: shareText,
      ),
    ),
  );
}
