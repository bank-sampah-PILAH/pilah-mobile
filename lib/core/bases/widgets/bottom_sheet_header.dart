import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/dialog_surface.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_handle.dart';

class BottomSheetHeader extends StatelessWidget {
  final String title;

  /// Apakah pegangan tarik di atas judul ikut ditampilkan.
  ///
  /// Null berarti otomatis: tampil pada bottom sheet, tersembunyi di dalam
  /// [DialogSurface] karena dialog tidak dapat ditarik dan pegangan di sana
  /// janji palsu. Picker yang memutuskannya sendiri memberi nilai eksplisit.
  final bool? showDragHandle;

  static const dragHandleKey = ValueKey('bottom-sheet-drag-handle');

  /// Cara menutup, bila bukan dengan menutup route.
  ///
  /// Default null berarti `context.pop()`, yang benar untuk bottom sheet dan
  /// dialog karena keduanya memang sebuah route. Panel berada inline di dalam
  /// body halaman, jadi ia harus memberikan caranya sendiri; tanpa ini tombol
  /// silangnya akan menutup halaman, bukan panelnya.
  final VoidCallback? onClose;

  const BottomSheetHeader({
    super.key,
    required this.title,
    this.showDragHandle,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDragHandle ?? !DialogSurface.of(context)) ...[
          const AppSheetHandle(key: dragHandleKey),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Judul mengambil ruang yang tersisa setelah tombol tutup, bukan
            // lebar alaminya. Tanpa ini judul sepanjang "Tambah Jenis Sampah"
            // melimpah ke kanan pada lebar telepon — 372 px ruang isi sheet
            // tidak cukup untuk judul 20 px tebal berdampingan dengan tombol
            // tutup 36 px, dan yang melimpah terpotong tanpa dapat dibaca.
            Expanded(
              child: Text(
                title,
                style: AppTextStyle.headline1.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onClose ?? () => context.pop(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child:
                    const Icon(Icons.close, color: AppColors.grey100, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
