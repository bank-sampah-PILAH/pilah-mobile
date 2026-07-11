import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';

class NasabahConfirmationDialog extends StatelessWidget {
  final bool isActivating;
  final String customerName;
  final String customerId;
  final NasabahCubit nasabahCubit;

  const NasabahConfirmationDialog({
    super.key,
    required this.isActivating,
    required this.customerName,
    required this.customerId,
    required this.nasabahCubit,
  });

  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color errorColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final bgColor = isActivating ? Colors.green[50] : Colors.orange[50];
    final iconColor = isActivating ? Colors.green[600] : Colors.orange[400];
    final iconData = isActivating ? Icons.check_box : Icons.warning_amber_rounded;

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
              isActivating ? 'Aktifkan Nasabah?' : 'Nonaktifkan Nasabah?',
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
                        ? 'Yakin ingin mengaktifkan kembali nasabah '
                        : 'Yakin ingin menonaktifkan nasabah ',
                  ),
                  TextSpan(
                    text: customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  TextSpan(
                    text: isActivating
                        ? '? Nasabah dapat bertransaksi kembali.'
                        : '? Nasabah tidak dapat bertransaksi.',
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
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: AppTextStyle.title1.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Mutate the data via Cubit
                      if (isActivating) {
                        nasabahCubit.activateNasabah(customerId);
                      } else {
                        nasabahCubit.deactivateNasabah(customerId);
                      }
                      
                      AppNotification.showSuccess(
                        context,
                        title: isActivating ? 'Nasabah Aktif' : 'Nasabah Nonaktif',
                        message: isActivating
                            ? '$customerName berhasil diaktifkan kembali.'
                            : '$customerName telah dinonaktifkan.',
                      );
                      
                      context.pop(); // Pop Dialog
                      context.pop(); // Pop Bottom Sheet
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActivating ? emeraldPrimary : errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isActivating ? 'Ya, Aktifkan' : 'Ya, Nonaktifkan',
                      style: AppTextStyle.title1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
