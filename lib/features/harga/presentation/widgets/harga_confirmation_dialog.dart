import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Confirmation step for activating / deactivating a jenis sampah.
///
/// Pops `true` to confirm and `false` to cancel; a barrier dismiss pops `null`,
/// so callers must treat a null result as a cancel. The dialog deliberately owns
/// no cubit and performs no API call — the caller keeps that, along with the
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

  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color errorColor = Color(0xFFDC2626);

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
    final bgColor = isActivating ? Colors.green[50] : Colors.orange[50];
    final iconColor = isActivating ? Colors.green[600] : Colors.orange[400];
    final iconData =
        isActivating ? Icons.check_box : Icons.warning_amber_rounded;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 32),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isActivating
                  ? 'Aktifkan Jenis Sampah?'
                  : 'Nonaktifkan Jenis Sampah?',
              style: AppTextStyle.headline1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyle.small.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: isActivating
                        ? 'Yakin ingin mengaktifkan kembali jenis sampah '
                        : 'Yakin ingin menonaktifkan jenis sampah ',
                  ),
                  TextSpan(
                    text: wasteName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  TextSpan(
                    text: isActivating
                        ? '? Item ini akan dapat digunakan dalam transaksi lagi.'
                        : '? Item ini tidak akan muncul pada pilihan transaksi.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: AppTextStyle.small.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isActivating ? emeraldPrimary : errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isActivating ? 'Ya, Aktifkan' : 'Ya, Nonaktifkan',
                      style: AppTextStyle.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
