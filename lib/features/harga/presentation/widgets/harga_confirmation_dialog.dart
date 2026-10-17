import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';

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
    final bgColor = isActivating ? Colors.green[50] : Colors.orange[50];
    final iconColor = isActivating ? Colors.green[600] : Colors.orange[400];
    final iconData =
        isActivating ? Icons.check_box : Icons.warning_amber_rounded;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
                  child: AppButton(
                    label: 'Batal',
                    variant: AppButtonVariant.neutral,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: isActivating ? 'Ya, Aktifkan' : 'Ya, Nonaktifkan',
                    variant: isActivating
                        ? AppButtonVariant.primary
                        : AppButtonVariant.destructive,
                    onPressed: () => Navigator.of(context).pop(true),
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
