import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_approval_timeline.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';

/// Replaces unavailable savings content while a membership needs a decision.
class NasabahVerificationHome extends StatelessWidget {
  const NasabahVerificationHome({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NasabahApprovalCubit>().state;
    final memberships = state is NasabahApprovalLoaded
        ? state.memberships
        : const <NasabahMembershipEntity>[];
    final membership = memberships
            .where((item) => item.status == MembershipStatus.pending)
            .firstOrNull ??
        memberships
            .where((item) => item.status == MembershipStatus.rejected)
            .firstOrNull ??
        memberships.firstOrNull;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: NasabahStyle.maxWidth),
          child: AppRefreshIndicator(
            onRefresh: () =>
                context.read<NasabahApprovalCubit>().load(silent: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Text('Beranda',
                    style: NasabahStyle.text(13, color: NasabahStyle.muted)),
                const SizedBox(height: 4),
                Text(
                  name.isEmpty ? 'Halo, Nasabah' : 'Halo, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NasabahStyle.text(20, weight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                if (state is NasabahApprovalInitial ||
                    state is NasabahApprovalLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is NasabahApprovalError)
                  _Notice(
                    icon: Icons.wifi_off_outlined,
                    title: 'Status belum bisa dimuat',
                    message: state.message,
                    action: 'Coba lagi',
                    onPressed: () =>
                        context.read<NasabahApprovalCubit>().load(),
                  )
                else if (membership == null)
                  _Notice(
                    icon: Icons.account_balance_outlined,
                    title: 'Belum ada pengajuan',
                    message: 'Pilih bank sampah untuk mulai menabung.',
                    action: 'Ajukan keanggotaan',
                    onPressed: () => context.push(RegisterNasabahScreen.route),
                  )
                else ...[
                  _StatusCard(membership: membership),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context
                          .push<bool>(
                        ApprovalBankSampahDetailPage.route,
                        extra: membership,
                      )
                          .then((_) {
                        if (context.mounted) {
                          context
                              .read<NasabahApprovalCubit>()
                              .load(silent: true);
                        }
                      }),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text('Lihat detail pengajuan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: NasabahStyle.emerald,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Perjalanan pengajuan',
                      style: NasabahStyle.text(17, weight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  MembershipApprovalTimeline(membership: membership),
                  const SizedBox(height: 16),
                  Text('Tarik ke bawah untuk memperbarui status.',
                      style: NasabahStyle.text(12, color: NasabahStyle.muted)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.membership});

  final NasabahMembershipEntity membership;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message, tint) = switch (membership.status) {
      MembershipStatus.pending => (
          Icons.hourglass_top_rounded,
          'Pengajuan sedang ditinjau',
          'Pengurus bank sampah sedang memverifikasi keanggotaan Anda. Belum ada tindakan yang perlu dilakukan.',
          const Color(0xFF9A6400),
        ),
      MembershipStatus.rejected => (
          Icons.info_outline_rounded,
          'Pengajuan belum disetujui',
          'Lihat alasan penolakan dan ajukan banding dari detail pengajuan.',
          const Color(0xFFC62828),
        ),
      MembershipStatus.approved => (
          Icons.info_outline_rounded,
          'Keanggotaan belum aktif',
          'Hubungi pengurus bank sampah untuk mengaktifkan keanggotaan Anda.',
          NasabahStyle.emerald,
        ),
    };

    return NasabahCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: tint.withValues(alpha: 0.1),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(height: 16),
          Text(title, style: NasabahStyle.text(20, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(membership.bankSampahNama,
              style: NasabahStyle.text(15,
                  weight: FontWeight.w600, color: NasabahStyle.emerald)),
          const SizedBox(height: 8),
          Text(message,
              style: NasabahStyle.text(13, color: NasabahStyle.muted)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => NasabahCard(
        padding: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: NasabahStyle.emerald),
            const SizedBox(height: 16),
            Text(title, style: NasabahStyle.text(20, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                style: NasabahStyle.text(13, color: NasabahStyle.muted)),
            const SizedBox(height: 16),
            TextButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      );
}
