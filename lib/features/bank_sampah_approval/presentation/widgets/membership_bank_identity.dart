import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_status_badge.dart';

class MembershipBankIdentity extends StatelessWidget {
  const MembershipBankIdentity({
    super.key,
    required this.membership,
    required this.nameStyle,
    required this.locationStyle,
  });

  final NasabahMembershipEntity membership;
  final TextStyle nameStyle;
  final TextStyle locationStyle;

  @override
  Widget build(BuildContext context) {
    final location = [membership.bankSampahKota, membership.bankSampahAlamat]
        .where((part) => part.trim().isNotEmpty)
        .join(' · ');
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.greenDark.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
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
                style: nameStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: locationStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        MembershipStatusBadge(status: membership.status),
      ],
    );
  }
}
