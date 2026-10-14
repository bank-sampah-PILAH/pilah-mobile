import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_list_item.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';
import 'package:pilah_mobile/services/di.dart';

/// Nasabah-facing list of the caller's own bank sampah memberships and their
/// approval status (PIL-232).
class ApprovalBankSampahListPage extends StatelessWidget {
  const ApprovalBankSampahListPage({super.key});

  static const route = '/approval-bank-sampah';

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthenticationBloc>().state;
    final userId = authState is Authenticated ? authState.authEntity.id : null;
    return BlocProvider<NasabahApprovalCubit>(
      create: (_) => di<NasabahApprovalCubit>()..load(),
      child: ApprovalBankSampahListView(userId: userId),
    );
  }
}

/// The list body is split out so widget tests can inject a cubit directly.
class ApprovalBankSampahListView extends StatefulWidget {
  const ApprovalBankSampahListView({super.key, this.userId});

  final String? userId;

  @override
  State<ApprovalBankSampahListView> createState() =>
      _ApprovalBankSampahListViewState();
}

class _ApprovalBankSampahListViewState
    extends State<ApprovalBankSampahListView> {
  late final ActiveMembershipSelection? _selection;
  Future<String?>? _selectedMembership;
  Set<String>? _eligibleMembershipIds;
  var _selectionRevision = 0;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null &&
        di.isRegistered<AppStorage>(instanceName: 'shared_preferences')) {
      _selection = ActiveMembershipSelection(
        di<AppStorage>(instanceName: 'shared_preferences'),
      );
    } else {
      _selection = null;
    }
  }

  Future<String?> _loadSelection(
    List<NasabahMembershipEntity> memberships,
    int revision,
  ) async {
    String? selected;
    try {
      selected = await _selection!.resolve(widget.userId!, memberships);
    } catch (_) {
      if (revision == _selectionRevision) {
        _selectedMembership = null;
        _eligibleMembershipIds = null;
      }
      _showSelectionError('Gagal memuat pilihan bank aktif. Coba lagi.');
    }
    if (!mounted || revision != _selectionRevision) return null;
    _selectedId = selected;
    return selected;
  }

  Future<String?> _selectionFor(List<NasabahMembershipEntity> memberships) {
    final eligibleIds = memberships
        .where(isSelectableMembership)
        .map((membership) => membership.id)
        .toSet();
    final previousIds = _eligibleMembershipIds;
    if (previousIds != null &&
        previousIds.length == eligibleIds.length &&
        previousIds.containsAll(eligibleIds)) {
      return _selectedMembership ?? Future.value(_selectedId);
    }

    _eligibleMembershipIds = eligibleIds;
    _selectedId = null;
    final revision = ++_selectionRevision;
    return _selectedMembership = _loadSelection(memberships, revision);
  }

  Future<void> _selectMembership(String membershipId) async {
    final userId = widget.userId;
    if (userId == null) return;
    try {
      await _selection!.select(userId, membershipId);
    } catch (_) {
      _showSelectionError('Gagal menyimpan pilihan bank aktif. Coba lagi.');
      return;
    }
    if (!mounted) return;
    setState(() => _selectedId = membershipId);
  }

  void _showSelectionError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text('Daftar Approval Bank Sampah', style: AppTextStyle.appBar),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                if (state is NasabahApprovalError) {
                  return EmptyView(
                    title: 'Gagal Memuat Data',
                    subtitle: state.message,
                    icon: Icons.error_outline,
                  );
                }
                if (state is! NasabahApprovalLoaded) {
                  return const SizedBox.shrink();
                }
                final memberships = state.memberships;
                final total = combinedActiveBalance(memberships);
                final selectionFuture =
                    _selection == null ? null : _selectionFor(memberships);
                if (memberships.isEmpty) {
                  return Column(
                    children: [
                      const Expanded(
                        child: EmptyView(
                          title: 'Belum Ada Pengajuan',
                          subtitle:
                              'Anda belum mengajukan keanggotaan ke bank sampah manapun.',
                          icon: Icons.hourglass_empty,
                        ),
                      ),
                      _applyButton(context),
                    ],
                  );
                }
                if (selectionFuture == null) {
                  return _membershipList(context, memberships, total);
                }
                return FutureBuilder<String?>(
                  future: selectionFuture,
                  builder: (context, snapshot) {
                    final loading =
                        snapshot.connectionState != ConnectionState.done;
                    final selected =
                        _selectedId ?? (loading ? null : snapshot.data);
                    return _membershipList(
                      context,
                      memberships,
                      total,
                      selectedId: selected,
                      selectionLoading: loading,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _membershipList(
    BuildContext context,
    List<NasabahMembershipEntity> memberships,
    BigInt total, {
    String? selectedId,
    bool selectionLoading = false,
  }) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: memberships.length + 2,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            color: const Color(0xFFF4F8F4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total saldo dari bank aktif'),
                  const SizedBox(height: 4),
                  Text(formatRupiahCents(total),
                      style: AppTextStyle.title1.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          );
        }
        if (index == memberships.length + 1) return _applyButton(context);
        final membership = memberships[index - 1];
        final selectable = _selection != null &&
            !selectionLoading &&
            isSelectableMembership(membership);
        return MembershipListItem(
          membership: membership,
          selected: membership.id == selectedId,
          onSelect: selectable ? () => _selectMembership(membership.id) : null,
          onTap: () {
            context
                .push<bool>(ApprovalBankSampahDetailPage.route,
                    extra: membership)
                .then((changed) {
              if (changed == true && context.mounted) {
                context.read<NasabahApprovalCubit>().load(silent: true);
              }
            });
          },
        );
      },
    );
  }

  Widget _applyButton(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: OutlinedButton.icon(
          onPressed: () => context.push(RegisterNasabahScreen.route),
          icon: const Icon(Icons.add),
          label: const Text('Daftar di bank lain'),
        ),
      );
}
