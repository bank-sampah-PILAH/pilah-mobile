import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';
// ponytail: temp QA-only entry for /pengumuman/kelola — remove after manual QA
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_kelola_page.dart';

/// Pengurus dashboard action area: a gojek-style menu grid. Every entry is a
/// tile — icon in a tinted squircle on top, label beneath — so a long label
/// never gets squeezed into a button row. Pencairan lives behind the Transaksi
/// Baru chooser (choosing it opens the same pencairan flow), not as its own
/// tile, so both routes stay reachable without duplicating the entry.
/// ponytail: menu currently QA-only for Pengumuman; finalize contents after QA.
class DashboardActionButtons extends StatelessWidget {
  const DashboardActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MenuTile(
            label: 'Transaksi Baru',
            icon: Icons.add_circle_outline,
            onTap: () => _openTransaksiChooser(context),
          ),
        ),
        Expanded(
          child: _MenuTile(
            label: 'Tambah\nNasabah',
            icon: Icons.person_add_outlined,
            onTap: () {
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
          ),
        ),
        Expanded(
          child: _MenuTile(
            label: 'Pengumuman',
            icon: Icons.campaign_outlined,
            onTap: () => context.push(PengumumanKelolaPage.route),
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
        context.push(DraftListPage.route);
    }
  }
}

/// One menu entry: icon in a tinted squircle on top, label under it, so a
/// long label never has to share a row with two button labels.
class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.greenDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.greenDark, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyle.extraSmall.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
            onTap: () => Navigator.of(context).pop(_TransaksiChoice.setoran),
          ),
          const SizedBox(height: 8),
          _ChoiceTile(
            icon: Icons.payments_outlined,
            title: 'Pencairan',
            subtitle: 'Buat draft, potongan, dan pencairan banyak nasabah',
            onTap: () => Navigator.of(context).pop(_TransaksiChoice.pencairan),
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
