import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/bank_sampah_label.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_config.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_transaction_menu.dart';

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
class RoleNavigationDrawer extends StatelessWidget {
  const RoleNavigationDrawer({
    super.key,
    required this.navigation,
  });

  final RoleNavigationConfig navigation;

  static const brandKey = ValueKey('drawer-brand');
  static const profileKey = ValueKey('drawer-profile');
  static const profileCardKey = ValueKey('drawer-profile-card');
  static ValueKey<String> destinationKey(int index) =>
      ValueKey('drawer-destination-$index');

  @override
  Widget build(BuildContext context) {
    final destinations = RoleDestinations.forRole(
      navigation.role,
      limitedNasabah: navigation.limitedNasabah,
    );
    if (destinations.isEmpty) return const SizedBox.shrink();

    final name = navigation.profileName?.trim() ?? '';
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BrandHeader(onHome: navigation.onHome),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 1, color: AppColors.border),
            ),
            _BankHeader(
              label: BankSampahLabel.of(navigation.bankSampahNama),
              initials: BankSampahLabel.initialsOf(navigation.bankSampahNama),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Text(
                'MENU',
                style: AppTextStyle.extraSmall.copyWith(
                  color: AppColors.grey100,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (navigation.role == 'pengelola' &&
                      navigation.onAddTransaction != null)
                    RoleTransactionMenu(
                      onSetoran: navigation.onAddTransaction!,
                      onClose: () => Navigator.maybeOf(context)?.maybePop(),
                    ),
                  for (var index = 0; index < destinations.length; index++)
                    _Destination(
                      key: destinationKey(index),
                      destination: destinations[index],
                      selected: navigation.currentIndex == index,
                      onTap: () {
                        Navigator.maybeOf(context)?.maybePop();
                        navigation.onSelected(index);
                      },
                    ),
                ],
              ),
            ),
            if (name.isNotEmpty)
              _ProfileFooter(
                name: name,
                email: navigation.profileEmail?.trim() ?? '',
                selected: navigation.profileSelected,
                onTap:
                    navigation.profileSelected || navigation.onProfile == null
                        ? null
                        : () {
                            Navigator.maybeOf(context)?.maybePop();
                            navigation.onProfile!();
                          },
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.onHome});

  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
        child: Semantics(
          button: true,
          label: 'Ke beranda',
          excludeSemantics: true,
          child: InkWell(
            key: RoleNavigationDrawer.brandKey,
            onTap: onHome,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 36,
                    height: 36,
                    semanticLabel: 'PILAH',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PILAH',
                    style: AppTextStyle.headline1.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _BankHeader extends StatelessWidget {
  const _BankHeader({required this.label, required this.initials});

  final String label;
  final String initials;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.greenDark,
              child: Text(
                initials,
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.small.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}

class _Destination extends StatelessWidget {
  const _Destination({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final RoleDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Semantics(
          button: true,
          selected: selected,
          label: destination.label,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.greenLight : null,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      destination.icon,
                      color: selected ? AppColors.greenDark : AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    destination.label,
                    style: AppTextStyle.small.copyWith(
                      color: selected ? AppColors.greenDark : AppColors.inkSoft,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({
    required this.name,
    required this.email,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String email;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Semantics(
          key: RoleNavigationDrawer.profileKey,
          button: true,
          selected: selected,
          label: 'Buka profil, $name',
          excludeSemantics: true,
          child: DecoratedBox(
            key: RoleNavigationDrawer.profileCardKey,
            decoration: BoxDecoration(
              color: selected ? AppColors.greenLight : null,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.greenDark,
                      child: Text(
                        initialsOf(name),
                        style: AppTextStyle.extraSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.small.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.extraSmall
                                  .copyWith(color: AppColors.grey100),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
