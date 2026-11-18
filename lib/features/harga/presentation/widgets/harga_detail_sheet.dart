import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/dialog_surface.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_detail_row.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_handle.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

/// Detail satu jenis sampah, dibuka dengan mengetuk barisnya.
///
/// Tidak mengubah apa pun: mengedit dan melihat riwayat harga adalah dua
/// pilihan di bawahnya, dan masing-masing membuka layarnya sendiri. Isi yang
/// sama dipakai di telepon (bottom sheet) dan di layar lebar (dialog); lihat
/// `showAdaptiveSurface`.
class HargaDetailSheet extends StatelessWidget {
  const HargaDetailSheet({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onRiwayat,
    this.embedded = false,
    this.showName = true,
  });

  final HargaEntity item;
  final VoidCallback onEdit;
  final VoidCallback onRiwayat;

  /// Di dalam panel samping, yang sudah punya latar, sudut, dan header-nya
  /// sendiri: tanpa wadah sheet dan tanpa pegangan tarik.
  final bool embedded;

  /// Bila false, nama tidak diulang di sini karena header di atasnya sudah
  /// memuatnya.
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final terjadwal = item.hargaTerjadwal;
    final berlakuMulai = item.berlakuMulai;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A dialog cannot be dragged, so it has no handle there.
        if (!embedded && !DialogSurface.of(context)) ...[
          const AppSheetHandle(),
          const SizedBox(height: AppSpacing.xl),
        ],
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(item.icon, color: AppColors.inkSoft, size: 28),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showName) ...[
                    Text(item.name,
                        style: AppTextStyle.title1
                            .copyWith(color: AppColors.black)),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Row(children: [
                    CustomStatusBadge(isActive: item.isActive),
                    const SizedBox(width: AppSpacing.sm),
                    CustomStatusBadge(statusText: item.badgeText),
                  ]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardOffWhite,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              AppDetailRow(label: 'Keterangan', value: item.subtitle),
              AppDetailRow(
                label: 'Harga beli',
                value: '${item.priceFormatted} / kg',
              ),
              if (berlakuMulai != null)
                AppDetailRow(
                  label: 'Berlaku sejak',
                  value: formatTanggalId(berlakuMulai.toLocal()),
                ),
              if (terjadwal != null)
                AppDetailRow(
                  label: 'Harga terjadwal',
                  value: '${CurrencyFormatter.formatRupiah(terjadwal.harga)} '
                      'mulai ${formatTanggalId(terjadwal.berlakuMulai.toLocal())}',
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Riwayat harga',
                variant: AppButtonVariant.outlined,
                icon: Icons.history,
                onPressed: onRiwayat,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
            ),
          ],
        ),
      ],
    );
    return embedded ? content : AppSheetContainer(child: content);
  }
}
