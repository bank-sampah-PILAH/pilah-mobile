import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_status_badge.dart';

/// One card in the approval list: bank icon, name, city + alamat, and a
/// status badge. Mirrors the bank sampah picker's list item
/// (`PilihBankSampahBottomSheet`) so a nasabah recognises the same bank
/// sampah identity here as when they picked it during registration.
class MembershipListItem extends StatelessWidget {
  final NasabahMembershipEntity membership;
  final VoidCallback onTap;

  const MembershipListItem({
    super.key,
    required this.membership,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.greenDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.recycling, color: AppColors.greenDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membership.bankSampahNama,
                    style: AppTextStyle.title1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [membership.bankSampahKota, membership.bankSampahAlamat]
                        .where((part) => part.trim().isNotEmpty)
                        .join(' · '),
                    style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MembershipStatusBadge(status: membership.status),
          ],
        ),
      ),
    );
  }
}
