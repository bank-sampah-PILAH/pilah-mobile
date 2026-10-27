import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';

/// Shared inputs for the desktop rail and narrow-screen drawer.
@immutable
class RoleNavigationConfig {
  const RoleNavigationConfig({
    required this.role,
    required this.currentIndex,
    required this.onSelected,
    this.bankSampahNama,
    this.profileName,
    this.profileEmail,
    this.onProfile,
    this.onHome,
    this.onAddTransaction,
    this.transactionSelected = false,
    this.profileSelected = false,
    this.limitedNasabah = false,
  });

  final String? role;
  final int? currentIndex;
  final ValueChanged<int> onSelected;
  final String? bankSampahNama;
  final String? profileName;
  final String? profileEmail;
  final VoidCallback? onProfile;
  final VoidCallback? onHome;
  final VoidCallback? onAddTransaction;
  final bool transactionSelected;
  final bool profileSelected;
  final bool limitedNasabah;

  /// Pengurus dengan menu Transaksi membuka Aktivitas sebagai "Riwayat" dari
  /// akordeon itu, bukan sebagai destinasi tersendiri.
  bool get hasTransactionMenu =>
      role == 'pengelola' && onAddTransaction != null;

  /// Posisi Aktivitas pada [destinations] bila ia pindah ke akordeon, selain
  /// itu null.
  int? riwayatIndex(List<RoleDestination> destinations) =>
      hasTransactionMenu ? RoleDestinations.riwayatIndex(destinations) : null;

  /// Pembuka Riwayat untuk [riwayat], atau null bila Riwayat tidak ada.
  VoidCallback? riwayatOpener(int? riwayat) =>
      riwayat == null ? null : () => onSelected(riwayat);

  /// `true` bila halaman yang terbuka adalah Riwayat.
  bool riwayatIsCurrent(int? riwayat) =>
      riwayat != null && currentIndex == riwayat;
}
