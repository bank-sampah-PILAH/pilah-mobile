import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Pill marking the bank the nasabah is currently banking with, so "Bank
/// sampah saya" says which of several approved banks the rest of the app is
/// reading. It deliberately reuses [MembershipStatusBadge]'s shape, since the
/// two sit side by side on a row.
class ActiveMembershipBadge extends StatelessWidget {
  const ActiveMembershipBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.greenDark,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Aktif',
          style: AppTextStyle.extraSmall.copyWith(
            color: AppColors.greenLight,
            fontWeight: AppFontWeight.semibold,
          ),
        ),
      );
}
