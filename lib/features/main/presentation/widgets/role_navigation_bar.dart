import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// Role-specific labels, independent of the router and its branch indices.
class RoleNavigationBar extends StatelessWidget {
  const RoleNavigationBar(
      {super.key,
      required this.role,
      required this.currentIndex,
      required this.onSelected});
  final String? role;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static bool isStaff(String? role) =>
      role == 'pengelola' || role == 'pengelola_induk';
  static bool supports(String? role) => role == 'nasabah' || isStaff(role);

  @override
  Widget build(BuildContext context) {
    if (!supports(role)) return const SizedBox.shrink();
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.greenDark,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      selectedLabelStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      currentIndex: currentIndex,
      onTap: onSelected,
      items: role == 'nasabah'
          ? const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), label: 'Beranda'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: 'Riwayat'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.storefront_outlined), label: 'Bank Sampah'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: 'Profil'),
            ]
          : const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline), label: 'Nasabah'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.local_offer_outlined), label: 'Harga'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.insert_drive_file_outlined),
                  label: 'Laporan'),
            ],
    );
  }
}
