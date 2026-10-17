import 'bank_sampah_label.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';
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
    this.profileName,
    this.profileEmail,
    this.onProfile,
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

  /// Akun yang sedang masuk, ditampilkan di kaki rail. Null atau hanya spasi
  /// berarti tidak ada kaki profil.
  final String? profileName;
  final String? profileEmail;

  /// Dipanggil saat kaki profil diketuk. Pemanggil yang memutuskan tujuannya.
  final VoidCallback? onProfile;

  final bool limitedNasabah;

  /// Kunci panel dan logo, untuk test.
  static const panelKey = ValueKey('rail-panel');
  static const logoKey = ValueKey('rail-logo');
  static const headerDividerKey = ValueKey('rail-header-divider');
  static const profileKey = ValueKey('rail-profile');
  static const profileCardKey = ValueKey('rail-profile-card');

  /// Label bank sampah, atau label umum bila namanya tidak diketahui.
  @override
  Widget build(BuildContext context) {
    final destinations =
        RoleDestinations.forRole(role, limitedNasabah: limitedNasabah);
    if (destinations.isEmpty) return const SizedBox.shrink();
    final extended = context.layoutBreakpoint == LayoutBreakpoint.expanded;
    final labelStyle = AppTextStyle.small;
    final name = profileName?.trim() ?? '';
    return DecoratedBox(
      key: panelKey,
      // Di atas isi rail: lebar minimumnya 256, jadi isinya melewati tepi yang
      // dibatasi border dan menimpanya bila border digambar di belakang.
      position: DecorationPosition.foreground,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.grey200)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: NavigationRail(
          extended: extended,
          leading: _RailHeader(
            label: BankSampahLabel.of(bankSampahNama),
            initials: BankSampahLabel.initialsOf(bankSampahNama),
            extended: extended,
          ),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.greenLight,
          selectedIndex: currentIndex,
          onDestinationSelected: onSelected,
          // none hanya wajib ketika extended; pada rail ringkas ia menyembunyikan
          // nama destinasi tanpa alasan dan meninggalkan ikon tanpa keterangan.
          labelType: extended
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.all,
          selectedIconTheme: const IconThemeData(color: AppColors.greenDark),
          unselectedIconTheme: const IconThemeData(color: AppColors.inkSoft),
          selectedLabelTextStyle: labelStyle.copyWith(
            color: AppColors.greenDark,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelTextStyle: labelStyle.copyWith(
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w500,
          ),
          trailing: name.isEmpty
              ? null
              : Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _ProfileFooter(
                      name: name,
                      email: profileEmail?.trim() ?? '',
                      extended: extended,
                      onTap: onProfile,
                    ),
                  ),
                ),
          destinations: [
            for (final destination in destinations)
              NavigationRailDestination(
                icon: Icon(destination.icon),
                label: Text(destination.label),
              ),
          ],
        ),
      ),
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
class _RailHeader extends StatelessWidget {
  const _RailHeader({
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

    final logo = Image.asset(
      'assets/logo.png',
      key: RoleNavigationRail.logoKey,
      width: extended ? 44 : 40,
      height: extended ? 44 : 40,
      semanticLabel: 'PILAH',
    );

    final bank = extended
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
        : Tooltip(message: label, child: badge);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment:
            extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (extended)
            Row(mainAxisSize: MainAxisSize.min, children: [
              logo,
              const SizedBox(width: 8),
              Text('PILAH',
                  style: AppTextStyle.headline1.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w700,
                  )),
            ])
          else
            logo,
          // Lebar dibatasi: slot leading memberi constraint tak terbatas.
          SizedBox(
            width: extended ? _leadingMaxWidth : 40,
            child: const Divider(
              key: RoleNavigationRail.headerDividerKey,
              height: 33,
              color: AppColors.border,
            ),
          ),
          bank,
          if (extended) ...[
            const SizedBox(height: 24),
            Text('MENU',
                style: AppTextStyle.extraSmall.copyWith(
                  color: AppColors.grey100,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                )),
          ],
        ],
      ),
    );
  }
}

/// Akun yang sedang masuk, menempel di dasar rail.
///
/// Pada rail yang sempit hanya avatar, dengan nama sebagai tooltip.
class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({
    required this.name,
    required this.email,
    required this.extended,
    required this.onTap,
  });

  final String name;
  final String email;
  final bool extended;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.greenDark,
      child: Text(
        initialsOf(name),
        style: AppTextStyle.extraSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Semantics(
        button: true,
        label: 'Buka profil, $name',
        excludeSemantics: true,
        // Garis tepi saja, tanpa isi: ripple InkWell digambar di Material di
        // bawahnya, dan isi yang menutupinya akan menyembunyikan ripple itu.
        child: DecoratedBox(
          key: RoleNavigationRail.profileCardKey,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            key: RoleNavigationRail.profileKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: extended
                ? ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: _leadingMaxWidth),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(children: [
                        avatar,
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.small.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black)),
                              if (email.isNotEmpty)
                                Text(email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.extraSmall
                                        .copyWith(color: AppColors.grey100)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(4),
                    child: Tooltip(message: name, child: avatar),
                  ),
          ),
        ),
      ),
    );
  }
}
