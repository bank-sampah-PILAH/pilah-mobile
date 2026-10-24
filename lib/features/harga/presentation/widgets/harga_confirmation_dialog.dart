import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';

/// Confirmation step for activating / deactivating a jenis sampah.
///
/// Pops `true` to confirm and `false` to cancel; a barrier dismiss pops `null`,
/// so callers must treat a null result as a cancel. The dialog deliberately owns
/// no state and performs no API call — the caller keeps that, along with the
/// error handling and the success notification, so a failed request cannot be
/// reported as a success.
class HargaConfirmationDialog extends StatelessWidget {
  final bool isActivating;
  final String wasteName;

  const HargaConfirmationDialog({
    super.key,
    required this.isActivating,
    required this.wasteName,
  });

  static const Color errorColor = AppColors.danger;

  /// Shows the dialog and resolves to whether the user confirmed.
  static Future<bool> show(
    BuildContext context, {
    required bool isActivating,
    required String wasteName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => HargaConfirmationDialog(
        isActivating: isActivating,
        wasteName: wasteName,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AppIconDialog(
      icon: isActivating ? Icons.check_box : Icons.warning_amber_rounded,
      tone: isActivating ? AppDialogTone.positive : AppDialogTone.warning,
      title:
          isActivating ? 'Aktifkan Jenis Sampah?' : 'Nonaktifkan Jenis Sampah?',
      message: [
        TextSpan(
          text: isActivating
              ? 'Yakin ingin mengaktifkan kembali jenis sampah '
              : 'Yakin ingin menonaktifkan jenis sampah ',
        ),
        TextSpan(
          text: wasteName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: isActivating
              ? '? Item ini akan dapat digunakan dalam transaksi lagi.'
              : '? Item ini tidak akan muncul pada pilihan transaksi.',
        ),
      ],
      confirmLabel: isActivating ? 'Ya, Aktifkan' : 'Ya, Nonaktifkan',
      destructive: !isActivating,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
  }
}
