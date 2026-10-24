import 'package:flutter/material.dart';
// CI benchmark scratch: documentation comment only, no behavior change.
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';

/// Approve/reject confirmation for a pending nasabah membership (PIL-188).
/// Pops with the trimmed catatan (alasan) the pengurus typed, or `null` when
/// cancelled.
class NasabahApprovalDialog extends StatefulWidget {
  final bool isApproving;
  final String customerName;

  const NasabahApprovalDialog({
    super.key,
    required this.isApproving,
    required this.customerName,
  });

  @override
  State<NasabahApprovalDialog> createState() => _NasabahApprovalDialogState();
}

class _NasabahApprovalDialogState extends State<NasabahApprovalDialog> {
  final TextEditingController _catatanController = TextEditingController();

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.isApproving ? 'Setujui Nasabah?' : 'Tolak Pengajuan?',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isApproving
                ? 'Setujui keanggotaan ${widget.customerName}? Nasabah dapat mulai menabung.'
                : 'Tuliskan alasan penolakan untuk ${widget.customerName}.',
            style: AppTextStyle.small,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _catatanController,
            maxLines: 2,
            decoration: appInputDecoration(
              hintText: widget.isApproving
                  ? 'Catatan (opsional)'
                  : 'Alasan penolakan',
              focusColor: widget.isApproving ? null : AppColors.danger,
            ),
          ),
        ],
      ),
      confirmLabel: widget.isApproving ? 'Setujui' : 'Tolak',
      destructive: !widget.isApproving,
      onConfirm: () =>
          Navigator.of(context).pop(_catatanController.text.trim()),
      onCancel: () => Navigator.of(context).pop(null),
    );
  }
}

/// Convenience opener so callers don't repeat the showDialog boilerplate.
/// Returns the catatan text on decision, `null` when cancelled.
Future<String?> showNasabahApprovalDialog(
  BuildContext context, {
  required bool isApproving,
  required String customerName,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => NasabahApprovalDialog(
      isApproving: isApproving,
      customerName: customerName,
    ),
  );
}
