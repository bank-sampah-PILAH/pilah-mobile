import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_tappable_card.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/active_membership_badge.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_bank_identity.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// One card in the approval list: bank icon, name, city + alamat, and a
/// status badge. Mirrors the bank sampah picker's list item
/// (`PilihBankSampahBottomSheet`) so a nasabah recognises the same bank
/// sampah identity here as when they picked it during registration.
class MembershipListItem extends StatelessWidget {
  final NasabahMembershipEntity membership;
  final VoidCallback onTap;

  /// Whether this is the bank the nasabah is banking with. The list decides
  /// it from the persisted choice, not from the membership's own fields.
  final bool isActive;

  const MembershipListItem({
    super.key,
    required this.membership,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppTappableCard(
      onTap: onTap,
      child: MembershipBankIdentity(
        membership: membership,
        nameStyle: AppTextStyle.title1.copyWith(
          color: AppColors.black,
          fontWeight: AppFontWeight.bold,
          fontSize: AppFontSize.lg,
        ),
        locationStyle: AppTextStyle.small.copyWith(color: AppColors.grey100),
        marker: isActive ? const ActiveMembershipBadge() : null,
      ),
    );
  }
}
