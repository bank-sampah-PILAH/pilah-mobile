import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:pilah_mobile/design/layout/dialog_surface.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_handle.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/design/widgets/app_tappable_card.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_bank_identity.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';

typedef MembershipBankDetailCallback = void Function(
  BuildContext context,
  NasabahMembershipEntity membership,
);

Future<void> showBankMembershipPanel(
  BuildContext context, {
  required AuthEntity owner,
  bool scrollToHistory = false,
  MembershipBankDetailCallback? onOpenActiveBank,
}) async {
  await showAdaptiveSurface<void>(
    context,
    builder: (_) => BankMembershipPanel(
      owner: owner,
      scrollToHistory: scrollToHistory,
      onOpenActiveBank: onOpenActiveBank,
    ),
  );
}

class BankMembershipPanel extends ConsumerStatefulWidget {
  const BankMembershipPanel({
    super.key,
    required this.owner,
    this.scrollToHistory = false,
    this.onOpenActiveBank,
  });

  final AuthEntity owner;
  final bool scrollToHistory;
  final MembershipBankDetailCallback? onOpenActiveBank;

  @override
  ConsumerState<BankMembershipPanel> createState() =>
      _BankMembershipPanelState();
}

class _BankMembershipPanelState extends ConsumerState<BankMembershipPanel> {
  final _historyKey = GlobalKey();
  bool _ownerDataReady = false;
  bool _loading = false;
  bool _loadFailed = false;
  bool _applying = false;
  String? _failedMembershipId;
  String? _savingMembershipId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  bool _ownsCurrentSession() => _sameOwner(
        widget.owner,
        ref.read(authenticationProvider),
      );

  Future<void> _reload({bool silent = false}) async {
    if (_loading || !_ownsCurrentSession()) return;
    setState(() {
      _loading = true;
      if (!silent) _ownerDataReady = false;
      _loadFailed = false;
    });
    try {
      await ref.read(nasabahApprovalProvider.notifier).load(silent: silent);
    } catch (_) {
      if (mounted && _ownsCurrentSession()) {
        setState(() => _loadFailed = true);
      }
    } finally {
      if (mounted && _ownsCurrentSession()) {
        setState(() {
          _loading = false;
          _ownerDataReady = true;
        });
        if (widget.scrollToHistory && !silent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final target = _historyKey.currentContext;
            if (mounted && target != null) {
              Scrollable.ensureVisible(target, duration: Duration.zero);
            }
          });
        }
      }
    }
  }

  Future<void> _select(NasabahMembershipEntity membership) async {
    if (_savingMembershipId != null || !_ownsCurrentSession()) return;
    setState(() {
      _savingMembershipId = membership.id;
      _failedMembershipId = null;
    });
    final saved =
        await ref.read(activeMembershipProvider.notifier).select(membership.id);
    if (!mounted || !_ownsCurrentSession()) return;
    if (!saved) {
      setState(() {
        _savingMembershipId = null;
        _failedMembershipId = membership.id;
      });
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _openHistoryDetail(NasabahMembershipEntity membership) async {
    if (!_ownsCurrentSession()) return;
    final changed = await context.push<bool>(
      ApprovalBankSampahDetailPage.route,
      extra: membership,
    );
    if (changed == true && mounted && _ownsCurrentSession()) {
      await _reload(silent: true);
    }
  }

  Future<void> _apply() async {
    if (_applying || !_ownsCurrentSession()) return;
    setState(() => _applying = true);
    try {
      final applied = await context.push<bool>(
        RegisterNasabahScreen.additionalRoute,
      );
      if (applied == true && mounted && _ownsCurrentSession()) {
        await _reload(silent: true);
      }
    } finally {
      if (mounted && _ownsCurrentSession()) {
        setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    if (!_sameOwner(widget.owner, authState)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text('Sesi berubah. Tutup panel dan masuk kembali.'),
        ),
      );
    }
    final state = ref.watch(nasabahApprovalProvider);
    final activeId = ref.watch(activeMembershipProvider).value;
    final panel = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!DialogSurface.of(context)) ...[
          const AppSheetHandle(),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(children: [
          Expanded(
            child: Text('Bank sampah saya', style: AppTextStyle.title1),
          ),
          if (DialogSurface.of(context))
            AppTapTarget(
              label: 'Tutup',
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close),
            ),
        ]),
        const SizedBox(height: AppSpacing.md),
        if (!_ownerDataReady)
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonListItem(),
            ),
          )
        else if (_loadFailed || state is NasabahApprovalError)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _PanelEmptyState(
              title: 'Gagal Memuat Data',
              message: state is NasabahApprovalError
                  ? state.message
                  : 'Coba periksa koneksi Anda.',
            ),
            AppButton(label: 'Coba lagi', onPressed: _reload),
          ])
        else if (state is NasabahApprovalLoaded)
          _membershipContent(state.memberships, activeId),
      ],
    );
    return DialogSurface.of(context)
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl), child: panel)
        : AppSheetContainer(child: panel);
  }

  Widget _membershipContent(
    List<NasabahMembershipEntity> memberships,
    String? activeId,
  ) {
    final currentByBank = <String, NasabahMembershipEntity>{};
    for (final membership in memberships) {
      final bankId = membership.bankSampahId.isEmpty
          ? membership.id
          : membership.bankSampahId;
      currentByBank.putIfAbsent(bankId, () => membership);
    }
    final current = currentByBank.values.toList();
    final followed = current
        .where((item) => item.status == MembershipStatus.approved)
        .toList()
      ..sort((a, b) {
        if (a.id == b.id) return 0;
        if (a.id == activeId) return -1;
        if (b.id == activeId) return 1;
        return a.bankSampahNama.compareTo(b.bankSampahNama);
      });
    final history = [...current]
      ..sort((a, b) => a.bankSampahNama.compareTo(b.bankSampahNama));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (followed.isNotEmpty) ...[
          Text('Bank diikuti', style: AppTextStyle.title1),
          const SizedBox(height: AppSpacing.sm),
          for (final membership in followed) ...[
            _MembershipRow(
              membership: membership,
              isActive: membership.id == activeId,
              selectable: membership.id != activeId &&
                  isSelectableMembership(membership) &&
                  _savingMembershipId == null,
              saving: membership.id == _savingMembershipId,
              failed: membership.id == _failedMembershipId,
              history: false,
              onTap: !membership.dapatDibuka
                  ? null
                  : membership.id != activeId
                      ? () => _select(membership)
                      : null,
              onDetail: membership.id == activeId &&
                      membership.dapatDibuka &&
                      widget.onOpenActiveBank != null
                  ? () {
                      if (_ownsCurrentSession()) {
                        widget.onOpenActiveBank!(context, membership);
                      }
                    }
                  : null,
              onRetry: () => _select(membership),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        KeyedSubtree(
          key: _historyKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Riwayat pengajuan', style: AppTextStyle.title1),
              const SizedBox(height: AppSpacing.sm),
              if (history.isEmpty)
                const _PanelEmptyState(
                  title: 'Belum ada riwayat pengajuan',
                  message: 'Pengajuan ke bank sampah akan muncul di sini.',
                )
              else
                for (final membership in history) ...[
                  _MembershipRow(
                    membership: membership,
                    isActive: false,
                    selectable: false,
                    saving: false,
                    failed: false,
                    history: true,
                    onTap: () => _openHistoryDetail(membership),
                    onDetail: null,
                    onRetry: () {},
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
        if (memberships.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Ajukan bank baru',
            icon: Icons.add,
            variant: AppButtonVariant.outlined,
            isLoading: _applying,
            onPressed: _applying || _savingMembershipId != null ? null : _apply,
          ),
        ],
      ],
    );
  }
}

class _MembershipRow extends StatelessWidget {
  const _MembershipRow({
    required this.membership,
    required this.isActive,
    required this.selectable,
    required this.saving,
    required this.failed,
    required this.history,
    required this.onTap,
    required this.onDetail,
    required this.onRetry,
  });

  final NasabahMembershipEntity membership;
  final bool isActive;
  final bool selectable;
  final bool saving;
  final bool failed;
  final bool history;
  final VoidCallback? onTap;
  final VoidCallback? onDetail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final unavailable = !history && !membership.dapatDibuka;
    final marker = history
        ? null
        : isActive
            ? const _ActiveLabel()
            : unavailable
                ? Text(
                    'Tidak tersedia',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.grey100,
                    ),
                  )
                : null;
    final row = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(children: [
        Expanded(
          child: MembershipBankIdentity(
            membership: membership,
            nameStyle: AppTextStyle.title1.copyWith(
              color: AppColors.black,
              fontSize: AppFontSize.md,
            ),
            locationStyle: AppTextStyle.small.copyWith(
              color: AppColors.grey100,
            ),
            marker: marker,
          ),
        ),
        if (saving)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (onDetail != null)
          AppButton(
            label: 'Detail Bank Sampah',
            size: AppButtonSize.compact,
            variant: AppButtonVariant.text,
            onPressed: onDetail,
          )
        else if (history)
          const Icon(Icons.chevron_right, color: AppColors.inkSoft)
        else if (unavailable)
          const SizedBox(width: AppSpacing.sm)
        else if (!selectable)
          const SizedBox(width: AppSpacing.sm),
      ]),
    );
    final content = onTap == null
        ? row
        : AppTapTarget(
            onTap: onTap,
            label: '${membership.bankSampahNama}, ${membership.status.name}',
            selected: isActive,
            child: row,
          );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      content,
      if (failed) ...[
        const SizedBox(height: AppSpacing.xs),
        Text('Pilihan belum tersimpan. Bank aktif tidak berubah.',
            style: AppTextStyle.small.copyWith(color: AppColors.danger)),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ]);
  }
}

class _PanelEmptyState extends StatelessWidget {
  const _PanelEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.info_outline, size: 32, color: AppColors.inkSoft),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyle.title1, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(message,
              style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              textAlign: TextAlign.center),
        ]),
      );
}

class _ActiveLabel extends StatelessWidget {
  const _ActiveLabel();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text('Aktif',
            style: AppTextStyle.extraSmall.copyWith(
              color: AppColors.greenDark,
            )),
      );
}

class BankMembershipHomeCard extends StatelessWidget {
  const BankMembershipHomeCard({
    super.key,
    required this.owner,
    required this.activeBankName,
    required this.onOpenActiveBank,
  });

  final AuthEntity owner;
  final String activeBankName;
  final MembershipBankDetailCallback onOpenActiveBank;

  @override
  Widget build(BuildContext context) => AppTappableCard(
        onTap: () => showBankMembershipPanel(
          context,
          owner: owner,
          onOpenActiveBank: onOpenActiveBank,
        ),
        child: Row(children: [
          const Icon(Icons.account_balance_outlined,
              color: AppColors.greenDark),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bank sampah saya', style: AppTextStyle.title1),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  activeBankName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.small.copyWith(color: AppColors.grey100),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey100),
        ]),
      );
}

bool _sameOwner(AuthEntity expected, AuthenticationStates current) =>
    current is Authenticated &&
    current.authEntity.role == 'nasabah' &&
    current.authEntity.id == expected.id &&
    current.authEntity.email == expected.email &&
    current.authEntity.token == expected.token;
