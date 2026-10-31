import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_side_sheet.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// Pengurus dashboard action area: the two things done most, side by side.
/// Pencairan remains visible but disabled in the Transaksi Baru chooser per
/// PIL-379. Everything else is a destination in the navigation, not a button.
class DashboardActionButtons extends StatelessWidget {
  const DashboardActionButtons({super.key, this.isWeb});

  /// Diteruskan ke [openSetoranBaru], yang memutuskan panel atau halaman
  /// penuh. Null berarti pakai `kIsWeb`.
  final bool? isWeb;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Transaksi Baru',
            icon: Icons.add,
            onPressed: () => _openTransaksiChooser(context, isWeb),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Tambah Nasabah',
            variant: AppButtonVariant.outlined,
            icon: Icons.person_add_outlined,
            onPressed: () {
              // 1. Trigger the route change to the Nasabah tab
              context.go('/nasabah');

              // 2. Wait for the tab transition animation to complete before showing the modal
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  showAdaptiveSurface(
                    context,
                    builder: (context) => const TambahNasabahBottomSheet(),
                  );
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openTransaksiChooser(BuildContext context, bool? isWeb) async {
    final choice = await showAdaptiveSurface<_TransaksiChoice>(
      context,
      builder: (context) => const _TransaksiChooserSheet(),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _TransaksiChoice.setoran:
        await openSetoranBaru(context, isWeb: isWeb);
    }
  }
}

enum _TransaksiChoice { setoran }

/// Lets the pengurus choose which transaction to record before opening its
/// own form — one beranda entry point for both, without merging the two
/// forms themselves (their data shapes are too different: multi-item vs
/// single-value) (PIL-282).
class _TransaksiChooserSheet extends StatelessWidget {
  const _TransaksiChooserSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHeader(title: 'Transaksi Baru'),
          const SizedBox(height: 8),
          _ChoiceTile(
            icon: Icons.add_circle_outline,
            title: 'Catat Setoran',
            subtitle: 'Rekam setoran sampah dari nasabah',
            onTap: () => Navigator.of(context).pop(_TransaksiChoice.setoran),
          ),
          const SizedBox(height: 8),
          const _ChoiceTile(
            icon: Icons.payments_outlined,
            title: 'Pencairan',
            subtitle: 'Buat draft, potongan, dan pencairan banyak nasabah',
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: enabled ? AppColors.greenLight : AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: enabled ? AppColors.greenDark : AppColors.grey100,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.title1.copyWith(
                      color: enabled ? AppColors.black : AppColors.grey100,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        AppTextStyle.small.copyWith(color: AppColors.grey100),
                  ),
                ],
              ),
            ),
            if (enabled)
              const Icon(Icons.chevron_right, color: AppColors.grey200),
          ],
        ),
      ),
    );
  }
}
