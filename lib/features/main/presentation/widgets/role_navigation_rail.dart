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
    this.bankSampahNama,
    this.limitedNasabah = false,
  });

  final String? role;

  /// Bank sampah yang sedang dikelola sesi ini.
  ///
  /// Diterima sebagai parameter, bukan dibaca dari AuthenticationBloc, supaya
  /// widget ini tetap presentasi murni dan dapat diuji tanpa bloc. Null atau
  /// hanya spasi diperlakukan sebagai tidak diketahui.
  final String? bankSampahNama;

  /// Indeks pada daftar destinasi role ini, bukan branch index.
  /// Destinasi yang sedang aktif, atau null bila tidak ada.
  ///
  /// Null dipakai pada rute di luar daftar destinasi, misalnya halaman profil
  /// staff: menandai Beranda di sana akan berbohong tentang posisi pengguna.
  /// Material sendiri menerima null pada selectedIndex untuk maksud yang sama.
  final int? currentIndex;

  /// Menerima indeks menu yang dipilih, bukan branch index. Penerjemahan ke
  /// branch dilakukan pemanggil, sama seperti pada bottom bar.
  final ValueChanged<int> onSelected;

  final bool limitedNasabah;

  /// Label bank sampah, atau label umum bila namanya tidak diketahui.
  String get _bankLabel {
    final trimmed = bankSampahNama?.trim() ?? '';
    return trimmed.isEmpty ? 'Bank Sampah' : trimmed;
  }

  /// Inisial dari maksimal dua kata pertama, untuk rail yang collapsed.
  String get _bankInitials {
    final words = _bankLabel
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'BS';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final destinations =
        RoleDestinations.forRole(role, limitedNasabah: limitedNasabah);
    if (destinations.isEmpty) return const SizedBox.shrink();
    final extended = context.layoutBreakpoint == LayoutBreakpoint.expanded;
    return NavigationRail(
      extended: extended,
      leading: _BankSampahContext(
        label: _bankLabel,
        initials: _bankInitials,
        extended: extended,
      ),
      backgroundColor: AppColors.cardOffWhite,
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      // none hanya wajib ketika extended; pada rail ringkas ia menyembunyikan
      // nama destinasi tanpa alasan dan meninggalkan ikon tanpa keterangan.
      labelType:
          extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
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

/// Lebar maksimum isi slot `leading`.
///
/// NavigationRail yang extended memakai `minExtendedWidth` 256 secara bawaan;
/// dikurangi padding horizontal 12 di kedua sisi, isinya mendapat 232.
const double _leadingMaxWidth = 232;

/// Penanda bank sampah pada kepala rail.
///
/// Pada rail yang extended nama ditulis penuh; pada rail collapsed lebarnya
/// hanya cukup untuk inisial, dan nama penuh dipasang sebagai tooltip supaya
/// konteksnya tidak hilang sama sekali.
class _BankSampahContext extends StatelessWidget {
  const _BankSampahContext({
    required this.label,
    required this.initials,
    required this.extended,
  });

  final String label;
  final String initials;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      height: 36,
      width: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.greenDark,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppTextStyle.extraSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: extended
          // Slot `leading` pada NavigationRail memberi constraint lebar tak
          // terbatas karena ia shrink-wrap isinya. Flex tidak dapat bekerja di
          // bawah constraint tak terbatas, jadi lebar dibatasi lebih dulu;
          // tanpa ini Row dengan Flexible melempar saat layout.
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _leadingMaxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  badge,
                  const SizedBox(width: 12),
                  // Nama panjang menyusut dan dipotong, bukan overflow.
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyle.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : Tooltip(message: label, child: badge),
    );
  }
}
