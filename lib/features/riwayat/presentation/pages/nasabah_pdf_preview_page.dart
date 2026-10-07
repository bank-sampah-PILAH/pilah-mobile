import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/utils/file_downloader.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';
import 'package:share_plus/share_plus.dart';

/// In-app PDF preview for the nasabah activity statement (PIL-315).
///
/// Owns exactly two things, and nothing about how the PDF was fetched:
/// rendering it in-app (pdfrx/PDFium, native, no web view) and saving its
/// bytes to Download with the follow-up share. The bytes arrive in memory,
/// so preview and download never re-request the server.
class NasabahPdfPreviewPage extends StatelessWidget {
  const NasabahPdfPreviewPage({super.key, required this.export});

  final StatementExport export;

  /// Saves to Download, then offers to share — identical to the XLSX export
  /// flow, so both exports behave the same app-wide.
  Future<void> _download(BuildContext context) async {
    final SavedFile saved;
    try {
      saved = await FileDownloader.save(
        filename: export.filename,
        bytes: Uint8List.fromList(export.bytes),
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
      message: 'Laporan PDF tersimpan di folder ${saved.folder}',
      actionLabel: 'Bagikan',
      onAction: () => SharePlus.instance.share(
        ShareParams(
          files: [XFile(saved.path)],
          text: 'Laporan Riwayat Aktivitas PILAH',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: NasabahStyle.background,
        appBar: AppBar(
          backgroundColor: NasabahStyle.emerald,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            export.filename,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              tooltip: 'Unduh',
              icon: const Icon(Icons.download_rounded),
              onPressed: () => _download(context),
            ),
          ],
        ),
        // The PDF itself is rendered by the pdfrx viewer (body below) — this
        // page only wraps it with the preview chrome and the download flow.
        body: _Viewer(export: export),
      );
}

/// pdfrx 2.4.x has no in-memory constructor: bytes go to a temp file and the
/// viewer reads from a path. Temp only — the durable copy is what the
/// download button writes on demand, and the temp dir is OS-cleaned.
class _Viewer extends StatelessWidget {
  const _Viewer({required this.export});

  final StatementExport export;

  File _tempFile() {
    final temp = Directory.systemTemp.createTempSync('riwayat_pdf');
    return File('${temp.path}/${export.filename}')
      ..writeAsBytesSync(export.bytes, flush: true);
  }

  @override
  Widget build(BuildContext context) => PdfViewer.file(_tempFile().path);
}