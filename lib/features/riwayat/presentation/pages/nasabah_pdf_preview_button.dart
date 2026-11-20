import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_page.dart';
import 'package:pilah_mobile/features/statement/presentation/providers/statement_export_provider.dart';

/// PDF icon beside the Setoran/Pencairan tabs (PIL-315). Fetches the
/// activity statement through [StatementExportNotifier] and opens the in-app
/// preview; from there the user downloads or shares it.
class NasabahPdfPreviewButton extends ConsumerWidget {
  const NasabahPdfPreviewButton(
      {super.key, required this.membershipId, this.previewViewer});

  final String membershipId;
  final Widget? previewViewer;

  Future<void> _openPreview(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(statementExportProvider.notifier);
    final loading = AppNotification.showLoading(
      context,
      title: 'Informasi',
      message: 'Menyiapkan laporan PDF...',
    );
    final export = await notifier.export(membershipId);
    if (!context.mounted) return;
    if (export == null) {
      await loading.dismiss();
      if (!context.mounted) return;
      AppNotification.showError(
        context,
        title: 'Gagal',
        message: notifier.error ?? 'Laporan PDF gagal dibuat. Coba lagi nanti.',
      );
      return;
    }
    // Push while the loading Flushbar is still up, then dismiss it: a route
    // pushed right after Flushbar.dismiss() can hit Navigator._debugLocked
    // (the lock outlives the completer by a frame). Dismissing a non-current
    // route uses removeRoute — instant, no animation, no lock.
    final navigator = Navigator.of(context, rootNavigator: true);
    final pushed = navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            NasabahPdfPreviewPage(export: export, viewer: previewViewer),
      ),
    );
    await loading.dismiss();
    await pushed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        tooltip: 'Pratinjau PDF',
        icon: const Icon(Icons.picture_as_pdf_outlined),
        color: NasabahStyle.ink,
        onPressed: () => _openPreview(context, ref),
      );
}
