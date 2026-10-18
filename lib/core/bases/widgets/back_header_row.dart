import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// The back tile + headline row the pushed pages share: grey-tile back button
/// on the left, bold screen title next to it (Transaksi Baru, Profil, and
/// the pengumuman screens' shape).
class BackHeaderRow extends StatelessWidget {
  const BackHeaderRow({super.key, required this.title, this.onBack});

  final String title;

  /// Defaults to popping; pass to override (deterministic tests).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack ?? () => context.pop(),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.arrow_back,
                color: AppColors.inkSoft, size: 20),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: AppTextStyle.appBar.copyWith(color: AppColors.black),
          ),
        ),
      ],
    );
  }
}
