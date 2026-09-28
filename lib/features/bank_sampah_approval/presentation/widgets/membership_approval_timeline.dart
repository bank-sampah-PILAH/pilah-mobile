import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/approval_log_step.dart';

/// A chronological, top-to-bottom view of a membership application.
class MembershipApprovalTimeline extends StatelessWidget {
  const MembershipApprovalTimeline({super.key, required this.membership});

  final NasabahMembershipEntity membership;

  @override
  Widget build(BuildContext context) {
    final history = membership.riwayat.reversed.toList(growable: false);
    final currentDecision = switch (membership.status) {
      MembershipStatus.pending => null,
      MembershipStatus.approved => ApprovalLogStatus.approved,
      MembershipStatus.rejected => ApprovalLogStatus.rejected,
    };
    final hasCurrentDecision =
        history.isNotEmpty && history.last.status == currentDecision;
    final showCurrentStep =
        membership.status == MembershipStatus.pending || !hasCurrentDecision;
    final stepCount = 1 + history.length + (showCurrentStep ? 1 : 0);
    var stepIndex = 0;

    return NasabahCard(
      child: Column(
        children: [
          _TimelineStep(
            icon: Icons.send_outlined,
            color: NasabahStyle.emerald,
            title: 'Pengajuan dikirim',
            subtitle: 'Data keanggotaan sudah diterima bank sampah.',
            isLast: ++stepIndex == stepCount,
          ),
          for (final entry in history)
            ApprovalLogStep(
              entry: entry,
              isLast: ++stepIndex == stepCount,
            ),
          if (showCurrentStep) _CurrentStatusStep(status: membership.status),
        ],
      ),
    );
  }
}

class _CurrentStatusStep extends StatelessWidget {
  const _CurrentStatusStep({required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, subtitle) = switch (status) {
      MembershipStatus.pending => (
          Icons.hourglass_top_rounded,
          const Color(0xFF9A6400),
          'Menunggu verifikasi pengurus',
          'Pengurus sedang meninjau pengajuan Anda.',
        ),
      MembershipStatus.approved => (
          Icons.check_rounded,
          NasabahStyle.emerald,
          'Keanggotaan disetujui',
          'Anda sudah bisa menggunakan layanan bank sampah.',
        ),
      MembershipStatus.rejected => (
          Icons.close_rounded,
          const Color(0xFFC62828),
          'Pengajuan ditolak',
          'Lihat alasan penolakan dan langkah berikutnya di atas.',
        ),
    };

    return _TimelineStep(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      isCurrent: true,
      isLast: true,
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isLast,
    this.isCurrent = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCurrent ? color.withValues(alpha: 0.12) : color,
                    shape: BoxShape.circle,
                    border:
                        isCurrent ? Border.all(color: color, width: 1.5) : null,
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isCurrent ? color : Colors.white,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: NasabahStyle.line),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: NasabahStyle.text(
                        14,
                        weight: FontWeight.w600,
                        color: isCurrent ? color : NasabahStyle.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: NasabahStyle.text(12, color: NasabahStyle.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
