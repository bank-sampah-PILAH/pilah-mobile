import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';

/// Bentuk navigasi untuk layar sempit.
///
/// Destinasinya tidak lagi ditentukan di sini: daftarnya dibaca dari
/// [RoleDestinations], yang juga dipakai navigation rail pada layar lebar.
/// Widget ini hanya memutuskan cara menggambar.
class RoleNavigationBar extends StatelessWidget {
  const RoleNavigationBar({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onSelected,
    this.limitedNasabah = false,
  });

  final String? role;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final bool limitedNasabah;

  static bool isStaff(String? role) => RoleDestinations.isStaff(role);
  static bool supports(String? role) => RoleDestinations.supports(role);

  static List<int> branchIndicesFor(String? role,
          {bool limitedNasabah = false}) =>
      RoleDestinations.branchIndicesFor(role, limitedNasabah: limitedNasabah);

  @override
  Widget build(BuildContext context) {
    final destinations =
        RoleDestinations.forRole(role, limitedNasabah: limitedNasabah);
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
