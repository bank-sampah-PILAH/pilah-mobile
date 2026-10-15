import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class BottomSheetHeader extends StatelessWidget {
  final String title;

  /// Apakah pegangan tarik di atas judul ikut ditampilkan.
  ///
  /// Default true, karena hampir semua pemakai header ini memang bottom sheet.
  /// Picker yang tampil sebagai dialog pada jendela lebar mematikannya: dialog
  /// tidak dapat ditarik, jadi di sana pegangan itu janji palsu.
  final bool showDragHandle;

  const BottomSheetHeader({
    super.key,
    required this.title,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDragHandle) ...[
          Center(
            child: Container(
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
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
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
