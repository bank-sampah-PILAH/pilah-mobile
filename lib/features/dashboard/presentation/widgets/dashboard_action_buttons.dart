import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/catat_pencairan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

class DashboardActionButtons extends StatelessWidget {
  const DashboardActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openTransaksiChooser(context),
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: Text(
              'Transaksi Baru',
              style: AppTextStyle.small.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // 1. Trigger the route change to the Nasabah tab
              context.go('/nasabah');

              // 2. Wait for the tab transition animation to complete before showing the modal
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const TambahNasabahBottomSheet(),
                  );
                }
              });
            },
            icon: const Icon(Icons.person_add_outlined,
                color: AppColors.greenDark, size: 20),
            label: Text(
              'Tambah\nNasabah',
              style: AppTextStyle.small.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.grey.shade300),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openTransaksiChooser(BuildContext context) async {
    final choice = await showModalBottomSheet<_TransaksiChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TransaksiChooserSheet(),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _TransaksiChoice.setoran:
        context.push(TransaksiBaruPage.route);
      case _TransaksiChoice.pencairan:
        context.push(CatatPencairanPage.route);
    }
  }
}

enum _TransaksiChoice { setoran, pencairan }

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            onTap: () =>
                Navigator.of(context).pop(_TransaksiChoice.setoran),
          ),
          const SizedBox(height: 8),
          _ChoiceTile(
            icon: Icons.payments_outlined,
            title: 'Catat Pencairan',
            subtitle: 'Rekam pencairan saldo untuk nasabah',
            onTap: () =>
                Navigator.of(context).pop(_TransaksiChoice.pencairan),
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
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.greenDark, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.title1.copyWith(
                      color: Colors.black87,
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
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
