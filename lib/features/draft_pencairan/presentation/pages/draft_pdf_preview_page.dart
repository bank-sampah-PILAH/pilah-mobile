import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

import '../../domain/model/draft_pencairan.dart';
import '../widgets/draft_file_actions.dart';
import '../widgets/pencairan_ui.dart';

/// The generated PDF, shown before anything is saved, so the pengurus can see
/// what it looks like and then download or share it.
class DraftPdfPreviewPage extends StatelessWidget {
  final DraftExport file;

  const DraftPdfPreviewPage({super.key, required this.file});

  /// Swaps the real viewer, which needs a platform renderer, for tests.
  @visibleForTesting
  static Widget Function(BuildContext, Uint8List)? viewBuilder;

  // The real viewer renders through a platform plugin that a unit test cannot
  // run; tests swap it with [viewBuilder] and the device run covers this.
  // coverage:ignore-start
  static Widget _defaultView(BuildContext context, Uint8List bytes) =>
      PdfPreview(
        build: (_) async => bytes,
        useActions: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        maxPageWidth: 700,
        pdfFileName: 'draft-pencairan.pdf',
        loadingWidget: const CircularProgressIndicator(),
        scrollViewDecoration: BoxDecoration(color: Colors.grey[200]),
      );
  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    final view = viewBuilder ?? _defaultView;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const PencairanHeader(title: 'Pratinjau PDF'),
            Expanded(child: view(context, file.bytes)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('bagikan'),
                  onPressed: () => bagikanBerkasDraft(file),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Bagikan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.greenDark,
                    side: const BorderSide(color: AppColors.greenDark),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('unduh'),
                  onPressed: () => simpanBerkasDraft(context, file),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Unduh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
