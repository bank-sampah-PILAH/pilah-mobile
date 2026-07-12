import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';

class HargaConfirmationDialog extends StatelessWidget {
  final bool isActivating;
  final HargaEntity hargaData;
  final HargaCubit hargaCubit;

  const HargaConfirmationDialog({
    super.key,
    required this.isActivating,
    required this.hargaData,
    required this.hargaCubit,
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
              isActivating ? 'Aktifkan Jenis Sampah?' : 'Nonaktifkan Jenis Sampah?',
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
                    text: hargaData.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
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
                    onPressed: () {
                      if (isActivating) {
                        final updatedHarga = HargaEntity(
                          id: hargaData.id,
                          kodeSampah: hargaData.kodeSampah,
                          name: hargaData.name,
                          price: hargaData.price,
                          priceFormatted: hargaData.priceFormatted,
                          category: hargaData.category,
                          subtitle: hargaData.subtitle,
                          badgeText: hargaData.badgeText,
                          icon: hargaData.icon,
                          iconColor: hargaData.iconColor,
                          isActive: true,
                        );
                        hargaCubit.updateHarga(updatedHarga);
                      } else {
                        hargaCubit.deactivateHarga(hargaData.id);
                      }

                      context.pop(); // close dialog
                      context.pop(); // close bottom sheet
                      
                      AppNotification.showSuccess(
                        context,
                        title: isActivating ? 'Jenis Sampah Aktif' : 'Jenis Sampah Nonaktif',
                        message: isActivating
                            ? '${hargaData.name} akan kembali muncul di daftar transaksi.'
                            : '${hargaData.name} telah disembunyikan dari transaksi.',
                      );
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
