import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/transaksi_chooser_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_side_sheet.dart';

/// Pengurus dashboard action area: the two things done most, side by side.
/// Which transactions Transaksi Baru offers is [_transaksiAksi]; everything
/// else is a destination in the navigation, not a button.
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
    final aksi = _transaksiAksi(context, isWeb);
    final choice = await showAdaptiveSurface<TransaksiPilihan>(
      context,
      builder: (context) => TransaksiChooserSheet(tersedia: aksi.keys.toSet()),
    );
    if (choice == null || !context.mounted) return;
    await aksi[choice]?.call();
  }

  /// Formulir yang dimiliki tombol Transaksi Baru, satu per transaksi yang
  /// sedang dibuka.
  ///
  /// Daftar ini **satu-satunya tempat** yang menentukan transaksi apa saja
  /// yang bisa dicatat: pemilihnya menawarkan kuncinya, dan tidak ada cabang
  /// lain yang perlu disesuaikan. Pencairan ditutup untuk handover (CPBI-31),
  /// jadi tidak ada entrinya; mengembalikannya berarti menambahkan satu entri
  /// di sini — yang membuka alur draft pencairan — lalu merilis ulang
  /// aplikasi, hardcode tanpa pengaturan jarak jauh seperti diminta CPBI-31.
  Map<TransaksiPilihan, Future<void> Function()> _transaksiAksi(
    BuildContext context,
    bool? isWeb,
  ) =>
      {
        TransaksiPilihan.setoran: () => openSetoranBaru(context, isWeb: isWeb),
      };
}
