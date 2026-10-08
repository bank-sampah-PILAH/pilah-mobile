import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';

/// Bentuk navigasi untuk layar lebar.
///
/// Dibuat sebagai widget terpisah dan bukan sebagai cabang di dalam
/// [RoleNavigationBar], supaya jalur render bottom bar yang sudah terbukti
/// tidak ikut berubah. Keduanya membaca destinasi dari sumber yang sama,
/// [RoleDestinations], sehingga menambah bentuk ini tidak dapat mengubah
/// destinasi siapa pun.
///
/// Label ditampilkan di samping ikon hanya pada blok expanded. Pada medium
/// lebarnya tidak cukup, jadi rail tetap sempit dan hanya memperlihatkan ikon
/// beserta label pendek di bawahnya.
class RoleNavigationRail extends StatelessWidget {
  const RoleNavigationRail({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onSelected,
    this.limitedNasabah = false,
  });

  final String? role;

  /// Indeks pada daftar destinasi role ini, bukan branch index.
  final int currentIndex;

  /// Menerima indeks menu yang dipilih, bukan branch index. Penerjemahan ke
  /// branch dilakukan pemanggil, sama seperti pada bottom bar.
  final ValueChanged<int> onSelected;

  final bool limitedNasabah;

  @override
  Widget build(BuildContext context) {
    final destinations =
        RoleDestinations.forRole(role, limitedNasabah: limitedNasabah);
    if (destinations.isEmpty) return const SizedBox.shrink();
    return NavigationRail(
      extended: context.layoutBreakpoint == LayoutBreakpoint.expanded,
      backgroundColor: AppColors.cardOffWhite,
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.none,
      selectedIconTheme: const IconThemeData(color: AppColors.greenDark),
      unselectedIconTheme: const IconThemeData(color: AppColors.grey100),
      selectedLabelTextStyle: AppTextStyle.extraSmall.copyWith(
        color: AppColors.greenDark,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: AppTextStyle.extraSmall,
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}
