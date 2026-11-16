import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/dashboard/analytics/dashboard_analytics.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/transaksi_chooser_sheet.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_side_sheet.dart';

/// Transaksi yang tersedia untuk Pengurus.
const transaksiPilihanTerbuka = {
  TransaksiPilihan.setoran,
  TransaksiPilihan.pencairan,
};

/// Pengurus dashboard action area: the two things done most, side by side.
/// Which transactions Transaksi Baru offers is [terbuka]; everything else is
/// a destination in the navigation, not a button.
class DashboardActionButtons extends ConsumerWidget {
  const DashboardActionButtons({
    super.key,
    this.isWeb,
    this.terbuka = transaksiPilihanTerbuka,
  });

  /// Diteruskan ke [openSetoranBaru], yang memutuskan panel atau halaman
  /// penuh. Null berarti pakai `kIsWeb`.
  final bool? isWeb;

  /// Transaksi yang bisa dicatat dari tombol ini.
  final Set<TransaksiPilihan> terbuka;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No enabled action can leave the chooser with nothing to select.
    assert(terbuka.isNotEmpty, 'Transaksi Baru tanpa transaksi yang terbuka');
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Transaksi Baru',
            icon: Icons.add,
            onPressed: () {
              dashboardQuickActionTapped(ref.read(analyticsClientProvider),
                  DashboardQuickAction.newTransaction);
              _openTransaksiBaru(context, isWeb);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Tambah Nasabah',
            variant: AppButtonVariant.outlined,
            icon: Icons.person_add_outlined,
            onPressed: () {
              dashboardQuickActionTapped(ref.read(analyticsClientProvider),
                  DashboardQuickAction.addNasabah);
              // 1. Trigger the route change to the Nasabah tab
              context.go('/nasabah');

              // 2. Wait for the tab transition animation to complete before showing the modal
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  showAdaptiveSurface(
                    context,
                    builder: (context) =>
                        const TambahNasabahBottomSheet(source: 'dashboard'),
                  );
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openTransaksiBaru(BuildContext context, bool? isWeb) async {
    // Skip a redundant chooser when this configuration has only one action.
    final choice = terbuka.length == 1
        ? terbuka.single
        : await showAdaptiveSurface<TransaksiPilihan>(
            context,
            builder: (context) => TransaksiChooserSheet(tersedia: terbuka),
          );
    if (choice == null || !context.mounted) return;
    await _openForm(context, choice, isWeb);
  }

  /// Formulir yang mencatat transaksi yang dipilih.
  ///
  /// Both actions stay wired here; availability is controlled by [terbuka].
  Future<void> _openForm(
    BuildContext context,
    TransaksiPilihan choice,
    bool? isWeb,
  ) async {
    switch (choice) {
      case TransaksiPilihan.setoran:
        await openSetoranBaru(context, isWeb: isWeb);
      case TransaksiPilihan.pencairan:
        await context.push(DraftListPage.route);
    }
  }
}
