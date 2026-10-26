import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

/// Pengurus dashboard action area: the two things done most, side by side.
/// Pengumuman is a navigation destination, not an action button here.
class DashboardActionButtons extends StatelessWidget {
  const DashboardActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Transaksi Baru',
            icon: Icons.add,
            onPressed: () => _openTransaksiChooser(context),
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

  Future<void> _openTransaksiChooser(BuildContext context) async {
    final createSetoran = await showAdaptiveSurface<bool>(
      context,
      builder: (context) => const _TransaksiChooserSheet(),
    );
    if (createSetoran != true || !context.mounted) return;
    context.push(TransaksiBaruPage.route);
  }
}

/// The setoran shortcut from the pengurus dashboard.
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
            onTap: () => Navigator.of(context).pop(true),
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
          color: Colors.grey[50],
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
                      color: enabled ? Colors.black87 : AppColors.grey100,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyle.small.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (enabled) Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
