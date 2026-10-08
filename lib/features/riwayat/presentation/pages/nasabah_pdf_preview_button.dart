import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/features/riwayat/presentation/pages/nasabah_pdf_preview_page.dart';
import 'package:pilah_mobile/features/statement/presentation/blocs/statement_export_cubit.dart';
import 'package:pilah_mobile/services/di.dart';

/// PDF icon beside the Setoran/Pencairan tabs (PIL-315). Fetches the
/// activity statement through [StatementExportCubit] and opens the in-app
/// preview; from there the user downloads or shares it.
class NasabahPdfPreviewButton extends StatelessWidget {
  const NasabahPdfPreviewButton({super.key, required this.membershipId});

  final String membershipId;

  Future<void> _openPreview(BuildContext context) async {
    final cubit = di<StatementExportCubit>();
    final loading = AppNotification.showLoading(
      context,
      title: 'Informasi',
      message: 'Menyiapkan laporan PDF...',
    );
    final export = await cubit.export(membershipId);
    if (!context.mounted) return;
    if (export == null) {
      await loading.dismiss();
      if (!context.mounted) return;
      AppNotification.showError(
        context,
        title: 'Gagal',
        message:
            cubit.state.error ?? 'Laporan PDF gagal dibuat. Coba lagi nanti.',
      );
      return;
    }
    // Start the push, then dismiss the loading toast before awaiting: the
    // toast is non-dismissible and awaiting the push would leave it mounted
    // under the PDF preview for the whole session (and trap the app behind
    // an invisible barrier on return). Dismissing a non-current route is
    // instant — removeRoute, no animation, and no Navigator._debugLocked
    // (the lock outlives the push's completer by a frame, the race that
    // started this dance).
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = MaterialPageRoute<void>(
      builder: (_) => NasabahPdfPreviewPage(export: export),
    );
    final pushed = navigator.push(route);
    await loading.dismiss();
    await pushed;
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Pratinjau PDF',
        icon: const Icon(Icons.picture_as_pdf_outlined),
        color: NasabahStyle.ink,
        onPressed: () => _openPreview(context),
      );
}
