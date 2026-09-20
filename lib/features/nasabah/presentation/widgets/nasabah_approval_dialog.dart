import 'package:flutter/material.dart';

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

  static const Color emeraldPrimary = Color(0xFF006D44);

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.isApproving ? 'Setujui Nasabah?' : 'Tolak Pengajuan?',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isApproving
                ? 'Setujui keanggotaan ${widget.customerName}? Nasabah dapat mulai menabung.'
                : 'Tuliskan alasan penolakan untuk ${widget.customerName}.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _catatanController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: widget.isApproving
                  ? 'Catatan (opsional)'
                  : 'Alasan penolakan',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.isApproving
                      ? emeraldPrimary
                      : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pop(_catatanController.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                widget.isApproving ? emeraldPrimary : Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: Text(widget.isApproving ? 'Setujui' : 'Tolak'),
        ),
      ],
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