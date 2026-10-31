import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';

/// Membuka konfirmasi "Hapus" untuk setoran [id]. Menjawab `true` bila
/// setoran berhasil dibatalkan.
Future<bool?> showBatalkanSetoranDialog(BuildContext context, String id) =>
    showDialog<bool>(
      context: context,
      builder: (context) => BatalkanSetoranDialog(id: id),
    );

/// Konfirmasi "Hapus" setoran (PIL-428). Hapus adalah pembatalan: setoran
/// tetap ada di riwayat dengan label Dibatalkan, tetapi tidak lagi dihitung.
/// Alasan wajib diisi, seperti saat mengedit setoran.
class BatalkanSetoranDialog extends ConsumerStatefulWidget {
  const BatalkanSetoranDialog({super.key, required this.id});

  final String id;

  static const alasanKey = ValueKey('batalkan-setoran-alasan');

  @override
  ConsumerState<BatalkanSetoranDialog> createState() =>
      _BatalkanSetoranDialogState();
}

class _BatalkanSetoranDialogState extends ConsumerState<BatalkanSetoranDialog> {
  final _alasan = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  Future<void> _hapus() async {
    if (_alasan.text.trim().isEmpty) {
      setState(() => _error = 'Alasan pembatalan wajib diisi');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(transaksiProvider.notifier).batalkanTransaksi(
        TransaksiBatalRequest(id: widget.id, alasan: _alasan.text));
    if (!mounted) return;
    if (result.detail == null) {
      setState(() {
        _saving = false;
        _error = result.error ?? 'Setoran gagal dibatalkan.';
      });
      return;
    }
    ref.read(aktivitasSelectionProvider.notifier).clear();
    ref.read(riwayatAktivitasProvider.notifier).load(silent: true);
    Navigator.of(context).pop(true);
    AppNotification.afterNavigation((ctx) => AppNotification.showSuccess(
          ctx,
          title: 'Berhasil',
          message: 'Setoran dibatalkan. Tetap tampil di riwayat dengan '
              'label Dibatalkan.',
        ));
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Hapus Setoran?',
      // A short form: on a wide window the message would stretch it edge to edge.
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setoran tetap tampil di riwayat dengan label "Dibatalkan", '
              'tetapi tidak lagi dihitung ke saldo nasabah maupun laporan. '
              'Saldo nasabah dihitung ulang.',
              style: AppTextStyle.small,
            ),
            const SizedBox(height: 12),
            TextField(
              key: BatalkanSetoranDialog.alasanKey,
              controller: _alasan,
              enabled: !_saving,
              maxLines: 2,
              maxLength: 255,
              decoration: appInputDecoration(
                hintText: 'Alasan pembatalan',
                errorText: _error,
                focusColor: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
      confirmLabel: 'Hapus',
      destructive: true,
      isLoading: _saving,
      onConfirm: _hapus,
      onCancel: () => Navigator.of(context).pop(false),
    );
  }
}
