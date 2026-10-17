import 'bank_sampah_label.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';

/// Bentuk navigasi untuk browser yang terlalu sempit untuk rail.
///
/// Aturannya tetap bahwa browser menyimpan navigasinya di sebelah kiri, tetapi
/// di bawah 600 rail 256px tidak dapat berbagi lebar dengan konten. Jadi
/// destinasi pindah ke balik tombol menu dan terbuka sebagai drawer dari tepi
/// kiri.
///
/// Seperti [RoleNavigationRail] dan [RoleNavigationBar], widget ini hanya
/// menggambar: destinasi dibaca dari [RoleDestinations], sehingga bentuk
/// ketiga ini tidak dapat memberi role mana pun destinasi tambahan.
///
/// Berbeda dari rail ringkas, drawer punya ruang penuh untuk label, jadi label
/// selalu ditampilkan.
class RoleNavigationDrawer extends StatelessWidget {
  const RoleNavigationDrawer({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onSelected,
    this.bankSampahNama,
    this.limitedNasabah = false,
  });

  final String? role;

  /// Bank sampah yang sedang dikelola sesi ini. Null atau hanya spasi
  /// diperlakukan sebagai tidak diketahui.
  final String? bankSampahNama;

  /// Indeks pada daftar destinasi role ini, bukan branch index.
  /// Destinasi yang sedang aktif, atau null bila tidak ada.
  ///
  /// Null dipakai pada rute di luar daftar destinasi, misalnya halaman profil
  /// staff: menandai Beranda di sana akan berbohong tentang posisi pengguna.
  /// Material sendiri menerima null pada selectedIndex untuk maksud yang sama.
  final int? currentIndex;

  /// Menerima indeks menu yang dipilih, bukan branch index.
  final ValueChanged<int> onSelected;

  final bool limitedNasabah;

  @override
  Widget build(BuildContext context) {
    final destinations =
        RoleDestinations.forRole(role, limitedNasabah: limitedNasabah);
    if (destinations.isEmpty) return const SizedBox.shrink();
    return NavigationDrawer(
      backgroundColor: AppColors.cardOffWhite,
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        // Ditutup lebih dulu, lalu dilaporkan: drawer yang tetap terbuka
        // menutupi halaman yang baru saja dibukanya.
        Navigator.maybeOf(context)?.maybePop();
        onSelected(index);
      },
      children: [
        _Header(label: BankSampahLabel.of(bankSampahNama)),
        for (final destination in destinations)
          NavigationDrawerDestination(
            icon: Icon(destination.icon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}

/// Kepala drawer: menyebut bank sampah mana yang sedang dikelola, sejajar
/// dengan kepala rail.
class _Header extends StatelessWidget {
  const _Header({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.small.copyWith(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bank sampah yang dikelola',
            style: AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
          ),
        ],
      ),
    );
  }
}
