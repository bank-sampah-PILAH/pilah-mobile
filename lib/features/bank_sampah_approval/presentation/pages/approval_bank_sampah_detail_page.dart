import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/expandable_text.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_appeal_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_appeal_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_approval_timeline.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_bank_identity.dart';

/// Detail view for one membership, pushed from [ApprovalBankSampahListView]
/// with the tapped [NasabahMembershipEntity] passed directly via GoRouter's
/// `extra` — the list already holds the full object, so this never re-fetches
/// by id.
class ApprovalBankSampahDetailPage extends StatelessWidget {
  final NasabahMembershipEntity membership;

  const ApprovalBankSampahDetailPage({super.key, required this.membership});

  static const route = '/approval-bank-sampah/detail';

  @override
  Widget build(BuildContext context) =>
      ApprovalBankSampahDetailView(membership: membership);
}

/// The detail body, split out from [ApprovalBankSampahDetailPage] so widget
/// tests can override its provider without going through the DI container.
class ApprovalBankSampahDetailView extends ConsumerWidget {
  final NasabahMembershipEntity membership;

  const ApprovalBankSampahDetailView({super.key, required this.membership});

  Future<void> _appeal(BuildContext context, WidgetRef ref) async {
    final pesan = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _AppealMessageDialog(),
    );
    if (pesan == null) return;
    ref
        .read(nasabahAppealProvider.notifier)
        .submit(membership.bankSampahId, pesan: pesan);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<NasabahAppealState>(nasabahAppealProvider, (previous, state) {
      if (state is NasabahAppealSuccess) {
        context.pop(true);
        AppNotification.afterNavigation((ctx) => AppNotification.showSuccess(
              ctx,
              title: 'Banding Diajukan',
              message:
                  'Pengajuan Anda telah dikirim ulang untuk ditinjau pengurus.',
            ));
      } else if (state is NasabahAppealFailure) {
        AppNotification.showError(
          context,
          title: 'Gagal Mengajukan Banding',
          message: state.message,
        );
      }
    });
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NasabahPageAppBar(
        title: membership.bankSampahNama,
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 24),
              if (membership.status == MembershipStatus.rejected) ...[
                _buildAppealButton(context, ref),
                const SizedBox(height: 24),
              ],
              Text(
                'Riwayat Persetujuan',
                style: AppTextStyle.title1.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 16),
              MembershipApprovalTimeline(membership: membership),
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
          Text(
            switch (membership.status) {
              MembershipStatus.pending => 'Pengajuan sedang ditinjau',
              MembershipStatus.approved => 'Keanggotaan aktif',
              MembershipStatus.rejected => 'Pengajuan belum disetujui',
            },
            style: AppTextStyle.title1.copyWith(
              color: AppColors.greenDark,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          MembershipBankIdentity(
            membership: membership,
            nameStyle: AppTextStyle.title1.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            locationStyle: AppTextStyle.small.copyWith(
              color: Colors.grey[500],
            ),
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
            ExpandableText(
              text: membership.alasanPenolakan ?? '-',
              style: AppTextStyle.small.copyWith(color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppealButton(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nasabahAppealProvider);
    return AppButton(
      label: 'Ajukan Banding',
      isLoading: state is NasabahAppealSubmitting,
      onPressed: () => _appeal(context, ref),
    );
  }
}

/// Collects the nasabah's appeal message before an appeal is submitted.
/// Pops `null` on cancel, or the entered text (possibly empty — the backend
/// treats a blank message as optional) on confirm.
class _AppealMessageDialog extends StatefulWidget {
  @override
  State<_AppealMessageDialog> createState() => _AppealMessageDialogState();
}

class _AppealMessageDialogState extends State<_AppealMessageDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Ajukan Banding',
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: appInputDecoration(
            hintText: 'Jelaskan perbaikan yang sudah Anda lakukan (opsional)'),
      ),
      confirmLabel: 'Kirim',
      onConfirm: () => Navigator.of(context).pop(_controller.text.trim()),
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
