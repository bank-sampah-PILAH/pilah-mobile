import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pilah_mobile/core/utils/report_export_sheet.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';

/// In-app PDF preview for the nasabah activity statement (PIL-315).
///
/// Owns exactly two things, and nothing about how the PDF was fetched:
/// rendering it in-app (pdfrx/PDFium, native, no web view) and saving its
/// bytes to Download with the follow-up share (the app-wide
/// save-then-share flow). The bytes arrive in memory, so preview and
/// download never re-request the server.
class NasabahPdfPreviewPage extends StatelessWidget {
  const NasabahPdfPreviewPage({super.key, required this.export});

  final StatementExport export;

  /// Saves to Download, then offers to share — identical to the XLSX export
  /// flow, so both exports behave the same app-wide.
  Future<void> _download(BuildContext context) => saveAndOfferShare(
        context,
        filename: export.filename,
        bytes: Uint8List.fromList(export.bytes),
        successMessage: (saved) =>
            'Laporan PDF tersimpan di folder ${saved.folder}',
        shareText: 'Laporan Riwayat Aktivitas PILAH',
      );

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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
/// download button writes on demand, and this state deletes its temp dir on
/// dispose (every preview open would otherwise leave the financial PDF on
/// disk until the OS cleans the temp dir).
class _Viewer extends StatefulWidget {
  const _Viewer({required this.export});

  final StatementExport export;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final Directory _tempDir;
  late final File _file;

  @override
  void initState() {
    super.initState();
    // Once per page instance: a parent rebuild (e.g. a theme change) must not
    // re-create the file and reload the viewer.
    _tempDir = Directory.systemTemp.createTempSync('riwayat_pdf');
    _file = File('${_tempDir.path}/${widget.export.filename}')
      ..writeAsBytesSync(widget.export.bytes, flush: true);
  }

  @override
  void dispose() {
    if (_tempDir.existsSync()) _tempDir.deleteSync(recursive: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PdfViewer.file(_file.path);
}
