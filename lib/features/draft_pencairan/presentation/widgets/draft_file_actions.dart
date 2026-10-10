import 'package:flutter/widgets.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/utils/file_downloader.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/model/draft_pencairan.dart';

/// Saves [file] to the downloads folder and says where it went, with a way to
/// share it from there. Shared by the Excel export and the PDF preview.
Future<void> simpanBerkasDraft(BuildContext context, DraftExport file) async {
  final SavedFile saved;
  try {
    saved = await FileDownloader.save(
      filename: file.filename,
      bytes: file.bytes,
    );
  } catch (e) {
    if (!context.mounted) return;
    AppNotification.showError(
      context,
      title: 'Gagal Menyimpan',
      message: 'Gagal menyimpan berkas: $e',
    );
    return;
  }
  if (!context.mounted) return;
  AppNotification.showSuccess(
    context,
    title: 'Berhasil',
    message: 'Berkas disimpan ke folder ${saved.folder}',
    actionLabel: 'Bagikan',
    onAction: () => SharePlus.instance.share(
      ShareParams(files: [XFile(saved.path)], text: 'Draft Pencairan PILAH'),
    ),
  );
}

/// Opens the OS share sheet with [file], without saving it first.
Future<void> bagikanBerkasDraft(DraftExport file) => SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            file.bytes,
            mimeType: 'application/pdf',
            name: file.filename,
          ),
        ],
        fileNameOverrides: [file.filename],
        text: 'Draft Pencairan PILAH',
      ),
    );
