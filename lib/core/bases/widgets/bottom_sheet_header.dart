import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/dialog_surface.dart';

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
          Center(
            child: Container(
              key: dragHandleKey,
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyle.headline1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            InkWell(
              onTap: onClose ?? () => context.pop(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.close, color: Colors.grey[600], size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
