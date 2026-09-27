import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/approval_log_step.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_status_badge.dart';
import 'package:pilah_mobile/services/di.dart';

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
    // A new instance per visit, like NasabahApprovalCubit: an appeal is
    // scoped to this one detail-page visit, not app-wide state.
    return BlocProvider<NasabahAppealCubit>(
      create: (_) => di<NasabahAppealCubit>(),
      child: ApprovalBankSampahDetailView(membership: membership),
    );
  }
}

/// The detail body, split out from [ApprovalBankSampahDetailPage] so widget
/// tests can inject a cubit directly with `BlocProvider.value` instead of
/// going through the DI container — mirrors the list page's own split.
class ApprovalBankSampahDetailView extends StatelessWidget {
  final NasabahMembershipEntity membership;

  const ApprovalBankSampahDetailView({super.key, required this.membership});

  Future<void> _appeal(BuildContext context) async {
    final cubit = context.read<NasabahAppealCubit>();
    final pesan = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _AppealMessageDialog(),
    );
    if (pesan == null) return;
    cubit.submit(membership.bankSampahId, pesan: pesan);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NasabahAppealCubit, NasabahAppealState>(
      listener: (context, state) {
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
      },
      child: Scaffold(
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
                if (membership.status == MembershipStatus.rejected) ...[
                  _buildAppealButton(context),
                  const SizedBox(height: 24),
                ],
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

  Widget _buildAppealButton(BuildContext context) {
    return BlocBuilder<NasabahAppealCubit, NasabahAppealState>(
      builder: (context, state) {
        final submitting = state is NasabahAppealSubmitting;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: submitting ? null : () => _appeal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Ajukan Banding',
                    style: AppTextStyle.small.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
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
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Ajukan Banding',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Jelaskan perbaikan yang sudah Anda lakukan (opsional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.greenDark),
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}
