import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_list_item.dart';

/// Nasabah-facing "Bank sampah saya": the caller's own bank sampah
/// memberships with their approval status (PIL-232) and which one is the
/// active bank (PIL-236).
///
/// Reachable from the stable nasabah dashboard, including sessions whose
/// membership is pending or rejected and cannot load dashboard data.
class ApprovalBankSampahListPage extends StatelessWidget {
  const ApprovalBankSampahListPage({super.key});

  static const route = '/approval-bank-sampah';

  @override
  Widget build(BuildContext context) => const ApprovalBankSampahListView();
}

/// The list body, split out from [ApprovalBankSampahListPage] so widget tests
/// can exercise the provider-backed list body directly.
class ApprovalBankSampahListView extends ConsumerWidget {
  const ApprovalBankSampahListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nasabahApprovalProvider);
    _loadInitialState(context, ref, state);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const NasabahPageAppBar(
        title: 'Bank sampah saya',
        showBack: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: AppRefreshIndicator(
            onRefresh: () =>
                ref.read(nasabahApprovalProvider.notifier).load(silent: true),
            child: _buildList(context, ref, state),
          ),
        ),
      ),
    );
  }

  void _loadInitialState(
    BuildContext context,
    WidgetRef ref,
    NasabahApprovalState state,
  ) {
    if (state is NasabahApprovalInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted &&
            ref.read(nasabahApprovalProvider) is NasabahApprovalInitial) {
          ref.read(nasabahApprovalProvider.notifier).load();
        }
      });
    }
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    NasabahApprovalState state,
  ) {
    if (state is NasabahApprovalLoading || state is NasabahApprovalInitial) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => const SkeletonListItem(),
      );
    }
    if (state is NasabahApprovalLoaded) {
      return _loadedList(context, ref, state);
    }
    if (state is NasabahApprovalError) {
      return EmptyView(
        title: 'Gagal Memuat Data',
        subtitle: state.message,
        icon: Icons.error_outline,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _loadedList(
    BuildContext context,
    WidgetRef ref,
    NasabahApprovalLoaded state,
  ) {
    final memberships = state.memberships;
    if (memberships.isEmpty) {
      return const EmptyView(
        title: 'Belum Ada Pengajuan',
        subtitle: 'Anda belum mengajukan keanggotaan ke bank sampah manapun.',
        icon: Icons.hourglass_empty,
      );
    }
    // While the choice is still being read the previous value is used, so a
    // refresh does not blink the marker off and on again.
    final activeId = ref.watch(activeMembershipProvider).value;
    return Column(
      children: [
        Expanded(child: _membershipList(context, ref, memberships, activeId)),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AppButton(
            label: 'Ajukan bank baru',
            icon: Icons.add,
            onPressed: () => _applyToAnotherBank(context, ref),
          ),
        ),
      ],
    );
  }

  /// PIL-539: the registration form, opened in-app for an account that
  /// already has a membership. A submitted application pops `true`, and the
  /// new one is pending, so the list is reloaded to show it.
  void _applyToAnotherBank(BuildContext context, WidgetRef ref) {
    context.push<bool>(RegisterNasabahScreen.additionalRoute).then((applied) {
      if (applied == true && context.mounted) {
        ref.read(nasabahApprovalProvider.notifier).load(silent: true);
      }
    });
  }

  Widget _membershipList(
    BuildContext context,
    WidgetRef ref,
    List<NasabahMembershipEntity> memberships,
    String? activeId,
  ) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: memberships.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final membership = memberships[index];
        return MembershipListItem(
          membership: membership,
          isActive: activeId != null && membership.id == activeId,
          onTap: () {
            context
                .push<bool>(
              ApprovalBankSampahDetailPage.route,
              extra: membership,
            )
                .then((changed) {
              // A successful appeal pops `true` and returns the membership to
              // pending, so refresh the stale list.
              if (changed == true && context.mounted) {
                ref.read(nasabahApprovalProvider.notifier).load(silent: true);
              }
            });
          },
        );
      },
    );
  }
}
