import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

/// Pill badge for a membership's [MembershipStatus], coloured distinctly per
/// status — pending amber (matching [NasabahListItem]'s pending badge),
/// approved green (the app's active/success colour), rejected red.
class MembershipStatusBadge extends StatelessWidget {
  final MembershipStatus status;

  const MembershipStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      MembershipStatus.pending => (
          'Menunggu',
          const Color(0xFFFFF8E1),
          const Color(0xFFB26A00),
        ),
      MembershipStatus.approved => (
          'Disetujui',
          AppColors.greenLight,
          AppColors.greenDark,
        ),
      MembershipStatus.rejected => (
          'Ditolak',
          const Color(0xFFFDECEA),
          const Color(0xFFC62828),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyle.extraSmall.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
