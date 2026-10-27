import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Header satu tampilan di panel samping atau bottom sheet: kembali di kiri,
/// judul dan baris keterangan di tengah, tutup di kanan.
///
/// Satu-satunya header di panel; isi di bawahnya tidak punya judul sendiri.
/// Kembali ([onBack]) hanya ada pada tampilan di dalam tampilan lain dan
/// selalu menuju tampilan induknya. Tutup ([onClose]) menutup seluruh panel,
/// dan tidak ada di bottom sheet, yang ditutup dengan menggesernya.
class AppPanelHeader extends StatelessWidget {
  const AppPanelHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onClose,
  });

  /// Tinggi tetap supaya isi di bawahnya tidak bergeser antar tampilan.
  static const double height = 56;

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          if (onBack != null) ...[
            _HeaderIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Kembali',
              onPressed: onBack!,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.title1.copyWith(color: AppColors.black),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyle.small.copyWith(color: AppColors.grey100),
                  ),
              ],
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: AppSpacing.sm),
            _HeaderIconButton(
              icon: Icons.close,
              tooltip: 'Tutup',
              onPressed: onClose!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Tombol ikon polos 40x40 untuk kembali dan tutup, sama di keduanya.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.inkSoft),
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        hoverColor: AppColors.fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
