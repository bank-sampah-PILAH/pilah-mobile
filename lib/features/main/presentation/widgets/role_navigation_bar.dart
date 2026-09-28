import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Keeps each role's labels and router branch destinations together.
class RoleNavigationBar extends StatelessWidget {
  const RoleNavigationBar({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onSelected,
  });

  final String? role;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static bool isStaff(String? role) =>
      role == 'pengelola' || role == 'pengelola_induk';
  static bool supports(String? role) => role == 'nasabah' || isStaff(role);

  static List<int> branchIndicesFor(String? role) => _destinationsFor(role)
      .map((destination) => destination.branchIndex)
      .toList(growable: false);

  static List<_RoleDestination> _destinationsFor(String? role) =>
      role == 'nasabah'
          ? _nasabahDestinations
          : isStaff(role)
              ? _staffDestinations
              : const [];

  @override
  Widget build(BuildContext context) {
    final destinations = _destinationsFor(role);
    if (destinations.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardOffWhite,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardOffWhite,
        selectedItemColor: AppColors.greenDark,
        unselectedItemColor: AppColors.grey100,
        showUnselectedLabels: true,
        selectedLabelStyle: AppTextStyle.extraSmall.copyWith(
          color: AppColors.greenDark,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyle.extraSmall,
        currentIndex: currentIndex,
        onTap: onSelected,
        items: [
          for (final destination in destinations)
            BottomNavigationBarItem(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _RoleDestination {
  const _RoleDestination(this.branchIndex, this.icon, this.label);

  final int branchIndex;
  final IconData icon;
  final String label;
}

// StatefulShellRoute order: dashboard, nasabah, harga, laporan, jadwal,
// customer history, customer bank, profile.
const _nasabahDestinations = <_RoleDestination>[
  _RoleDestination(0, Icons.home_outlined, 'Beranda'),
  _RoleDestination(5, Icons.account_balance_wallet_outlined, 'Tabungan'),
  _RoleDestination(4, Icons.calendar_month_outlined, 'Jadwal'),
  _RoleDestination(7, Icons.person_outline, 'Profil'),
];

const _staffDestinations = <_RoleDestination>[
  _RoleDestination(0, Icons.grid_view_rounded, 'Dashboard'),
  _RoleDestination(1, Icons.people_outline, 'Nasabah'),
  _RoleDestination(2, Icons.local_offer_outlined, 'Harga'),
  _RoleDestination(3, Icons.insert_drive_file_outlined, 'Laporan'),
  _RoleDestination(4, Icons.calendar_month_outlined, 'Jadwal'),
];
