import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_list_item.dart';
import 'package:pilah_mobile/services/di.dart';

/// Nasabah-facing list of the caller's own bank sampah memberships and their
/// approval status (PIL-232).
///
/// Pushed rather than tab-hosted: the real dashboard entry point is a
/// deferred follow-up (PIL-225 is still an open, unmerged PR), so this is
/// reached from a temporary entry point on the nasabah's post-onboarding
/// landing page instead.
class ApprovalBankSampahListPage extends StatelessWidget {
  const ApprovalBankSampahListPage({super.key});

  static const route = '/approval-bank-sampah';

  @override
  Widget build(BuildContext context) {
    // A new instance per visit: membership data is per-user and this cubit is
    // not app-scoped (see NasabahApprovalCubit's doc comment), so it is
    // created and loaded here rather than provided once at the app root.
    return BlocProvider<NasabahApprovalCubit>(
      create: (_) => di<NasabahApprovalCubit>()..load(),
      child: const ApprovalBankSampahListView(),
    );
  }
}

/// The list body, split out from [ApprovalBankSampahListPage] so widget tests
/// can inject a cubit directly with `BlocProvider.value` instead of going
/// through the DI container.
class ApprovalBankSampahListView extends StatelessWidget {
  const ApprovalBankSampahListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          'Daftar Approval Bank Sampah',
          style: AppTextStyle.appBar,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: AppRefreshIndicator(
            onRefresh: () =>
                context.read<NasabahApprovalCubit>().load(silent: true),
            child: BlocBuilder<NasabahApprovalCubit, NasabahApprovalState>(
              builder: (context, state) {
                if (state is NasabahApprovalLoading ||
                    state is NasabahApprovalInitial) {
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: 5,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) => const SkeletonListItem(),
                  );
                }

                if (state is NasabahApprovalLoaded) {
                  final memberships = state.memberships;
                  if (memberships.isEmpty) {
                    return const EmptyView(
                      title: 'Belum Ada Pengajuan',
                      subtitle:
                          'Anda belum mengajukan keanggotaan ke bank sampah manapun.',
                      icon: Icons.hourglass_empty,
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: memberships.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final membership = memberships[index];
                      return MembershipListItem(
                        membership: membership,
                        onTap: () => context.push(
                          ApprovalBankSampahDetailPage.route,
                          extra: membership,
                        ),
                      );
                    },
                  );
                }

                // Rendered as a scrollable EmptyView rather than a blank box
                // so a failed load can be retried by pulling down.
                if (state is NasabahApprovalError) {
                  return EmptyView(
                    title: 'Gagal Memuat Data',
                    subtitle: state.message,
                    icon: Icons.error_outline,
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}
