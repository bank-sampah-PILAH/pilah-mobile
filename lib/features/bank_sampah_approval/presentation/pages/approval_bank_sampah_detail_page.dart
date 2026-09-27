import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/approval_log_step.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_status_badge.dart';

/// Detail view for one membership, pushed from [ApprovalBankSampahListView]
/// with the tapped [NasabahMembershipEntity] passed directly via GoRouter's
/// `extra` — the list already holds the full object, so this never re-fetches
/// by id.
class ApprovalBankSampahDetailPage extends StatelessWidget {
  final NasabahMembershipEntity membership;

  const ApprovalBankSampahDetailPage({super.key, required this.membership});

  static const route = '/approval-bank-sampah/detail';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(membership.bankSampahNama, style: AppTextStyle.appBar),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 24),
              Text(
                'Riwayat Persetujuan',
                style: AppTextStyle.title1.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  membership.bankSampahKota,
                  style: AppTextStyle.small.copyWith(color: Colors.grey[600]),
                ),
              ),
              MembershipStatusBadge(status: membership.status),
            ],
          ),
          if (membership.status == MembershipStatus.rejected) ...[
            const SizedBox(height: 16),
            Text(
              'Alasan Penolakan',
              style: AppTextStyle.extraSmall.copyWith(
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              membership.alasanPenolakan ?? '-',
              style: AppTextStyle.small.copyWith(color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (membership.riwayat.isEmpty) {
      return Text(
        'Menunggu keputusan pengurus',
        style: AppTextStyle.small.copyWith(color: Colors.grey[600]),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < membership.riwayat.length; i++)
          ApprovalLogStep(
            entry: membership.riwayat[i],
            isLast: i == membership.riwayat.length - 1,
          ),
      ],
    );
  }
}
