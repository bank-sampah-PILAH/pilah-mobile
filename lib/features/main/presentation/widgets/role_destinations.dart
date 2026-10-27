import 'package:flutter/material.dart';

/// Satu tujuan navigasi: ikon, label, dan branch StatefulShellRoute yang
/// dituju.
class RoleDestination {
  const RoleDestination(
    this.branchIndex,
    this.icon,
    this.label, {
    this.inBottomBar = true,
    this.disabled = false,
  });

  /// Indeks branch pada StatefulShellRoute, bukan posisi pada menu. Keduanya
  /// berbeda: menu nasabah menampilkan branch 0, 5, 4, 7 pada posisi 0..3.
  final int branchIndex;
  final IconData icon;
  final String label;

  /// `false` untuk destinasi yang hanya muat di rail dan drawer: bottom bar
  /// tidak nyaman dengan lebih dari lima. Tujuannya tetap dapat dicapai di
  /// aplikasi lewat jalan lain (Profil).
  final bool inBottomBar;

  /// A disabled destination stays visible but cannot be selected.
  final bool disabled;
}

/// Sumber tunggal daftar destinasi per role.
///
/// Dipakai bersama oleh bottom navigation (layar sempit) dan navigation rail
/// (layar lebar). Keduanya hanya memilih cara menggambar; *destinasi mana*
/// yang dimiliki sebuah role diputuskan di sini saja, sehingga menambah
/// bentuk navigasi baru tidak mungkin diam-diam mengubah menu siapa pun.
///
/// Urutan daftar adalah urutan tampil, dan indeks pada daftar inilah yang
/// dipakai sebagai currentIndex oleh kedua bentuk.
abstract final class RoleDestinations {
  /// `true` bila [role] adalah pengurus atau pengelola induk.
  static bool isStaff(String? role) =>
      role == 'pengelola' || role == 'pengelola_induk';

  /// Branch Aktivitas. Pengurus di web membukanya sebagai "Riwayat" dari
  /// akordeon Transaksi, bukan sebagai destinasi tersendiri.
  static const riwayatBranch = 3;

  /// Posisi Aktivitas pada [destinations], atau null bila tidak ada.
  static int? riwayatIndex(List<RoleDestination> destinations) {
    final index = destinations
        .indexWhere((destination) => destination.branchIndex == riwayatBranch);
    return index < 0 ? null : index;
  }

  /// `true` bila [role] memiliki navigasi sama sekali.
  static bool supports(String? role) => role == 'nasabah' || isStaff(role);

  /// Destinasi untuk [role].
  ///
  /// [limitedNasabah] hanya berlaku bagi nasabah yang keanggotaannya belum
  /// disetujui; bagi staff nilainya diabaikan.
  ///
  /// [bottomBar] menyaring destinasi yang tidak muat di bottom bar.
  static List<RoleDestination> forRole(String? role,
          {bool limitedNasabah = false, bool bottomBar = false}) =>
      _forRole(role, limitedNasabah: limitedNasabah)
          .where((destination) => !bottomBar || destination.inBottomBar)
          .toList(growable: false);

  static List<RoleDestination> _forRole(String? role,
          {required bool limitedNasabah}) =>
      switch (role) {
        'nasabah' when limitedNasabah => _limitedNasabah,
        'nasabah' => _nasabah,
        final other when isStaff(other) => _staff,
        // Gagal tertutup, dan sengaja menjadi baris terakhir: role yang tidak
        // dikenal mendapat daftar kosong, bukan menu staff.
        _ => const [],
      };

  /// Branch index setiap destinasi [role], berurutan sesuai tampilan.
  static List<int> branchIndicesFor(String? role,
          {bool limitedNasabah = false, bool bottomBar = false}) =>
      forRole(role, limitedNasabah: limitedNasabah, bottomBar: bottomBar)
          .map((destination) => destination.branchIndex)
          .toList(growable: false);
}

// Urutan branch StatefulShellRoute: dashboard, nasabah, harga, laporan,
// jadwal, customer history, customer bank, profile, pengumuman.
const _nasabah = <RoleDestination>[
  RoleDestination(0, Icons.home_outlined, 'Beranda'),
  RoleDestination(5, Icons.account_balance_wallet_outlined, 'Tabungan'),
  RoleDestination(4, Icons.calendar_month_outlined, 'Jadwal'),
  RoleDestination(7, Icons.person_outline, 'Profil'),
];

const _limitedNasabah = <RoleDestination>[
  RoleDestination(0, Icons.home_outlined, 'Beranda'),
  RoleDestination(7, Icons.person_outline, 'Profil'),
];

const _staff = <RoleDestination>[
  RoleDestination(0, Icons.grid_view_rounded, 'Dashboard'),
  RoleDestination(1, Icons.people_outline, 'Nasabah'),
  RoleDestination(2, Icons.local_offer_outlined, 'Harga'),
  RoleDestination(3, Icons.insert_drive_file_outlined, 'Aktivitas'),
  RoleDestination(4, Icons.calendar_month_outlined, 'Jadwal'),
  RoleDestination(
    8,
    Icons.campaign_outlined,
    'Pengumuman',
    inBottomBar: false,
    disabled: true,
  ),
];
