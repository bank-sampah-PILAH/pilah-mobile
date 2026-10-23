import 'package:flutter/material.dart';

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
}
