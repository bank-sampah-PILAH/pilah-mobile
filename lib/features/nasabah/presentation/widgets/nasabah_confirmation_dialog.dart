import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

class NasabahConfirmationDialog extends StatefulWidget {
  final bool isActivating;
  final String customerName;
  final String customerId;
  final NasabahNotifier nasabahNotifier;

  const NasabahConfirmationDialog({
    super.key,
    required this.isActivating,
    required this.customerName,
    required this.customerId,
    required this.nasabahNotifier,
  });

  static const Color errorColor = AppColors.danger;

  @override
  State<NasabahConfirmationDialog> createState() =>
      _NasabahConfirmationDialogState();
}

class _NasabahConfirmationDialogState extends State<NasabahConfirmationDialog> {
  bool _isProcessing = false;

  Future<void> _confirm() async {
    // The root overlay stays mounted after the dialog/sheet are popped, so use
    // it to host the notification instead of this dialog's (soon defunct) context.
    final overlayContext = Navigator.of(context, rootNavigator: true).context;
    final dialogContext = context;

    setState(() => _isProcessing = true);
    final error = await widget.nasabahNotifier
        .setNasabahStatus(widget.customerId, widget.isActivating);
    if (!mounted || !dialogContext.mounted) return;
    setState(() => _isProcessing = false);

    if (error == null) {
      dialogContext.pop(); // Dialog
      dialogContext.pop(); // Bottom sheet
      AppNotification.showSuccess(
        overlayContext,
        title: widget.isActivating ? 'Nasabah Aktif' : 'Nasabah Nonaktif',
        message: widget.isActivating
            ? '${widget.customerName} berhasil diaktifkan kembali.'
            : '${widget.customerName} telah dinonaktifkan.',
      );
    } else {
      dialogContext.pop(); // Dialog only, keep the sheet so the user can retry
      AppNotification.showError(
        overlayContext,
        title: 'Gagal',
        message: error.displayMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activating = widget.isActivating;
    return AppIconDialog(
      icon: activating ? Icons.check_box : Icons.warning_amber_rounded,
      tone: activating ? AppDialogTone.positive : AppDialogTone.warning,
      title: activating ? 'Aktifkan Nasabah?' : 'Nonaktifkan Nasabah?',
      message: [
        TextSpan(
          text: activating
              ? 'Yakin ingin mengaktifkan kembali nasabah '
              : 'Yakin ingin menonaktifkan nasabah ',
        ),
        TextSpan(
          text: widget.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: activating
              ? '? Nasabah dapat bertransaksi kembali.'
              : '? Nasabah tidak dapat bertransaksi.',
        ),
      ],
      confirmLabel: activating ? 'Ya, Aktifkan' : 'Ya, Nonaktifkan',
      destructive: !activating,
      isLoading: _isProcessing,
      onConfirm: _confirm,
      onCancel: () => context.pop(),
    );
  }
}
