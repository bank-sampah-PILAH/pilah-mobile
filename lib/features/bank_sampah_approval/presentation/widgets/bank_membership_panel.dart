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
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_handle.dart';
import 'package:pilah_mobile/design/widgets/app_tappable_card.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_bank_detail.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
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
  await context.push<void>(Uri(
    path: ApprovalBankSampahListPage.route,
    queryParameters: scrollToHistory ? {'tab': 'history'} : null,
  ).toString());
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

class _BankMembershipPanelState extends ConsumerState<BankMembershipPanel>
    with SingleTickerProviderStateMixin {
  final _historyKey = GlobalKey();
  bool _ownerDataReady = false;
  bool _loading = false;
  bool _loadFailed = false;
  bool _applying = false;
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.scrollToHistory ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _openHistoryDetail(NasabahMembershipEntity membership) async {
    if (!_ownsCurrentSession()) return;
    final changed = await showAdaptiveSurface<bool>(
      context,
      builder: (_) => ApprovalBankSampahDetailView(
        membership: membership,
        allowActiveSwitch: false,
      ),
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
        _tabController.animateTo(1);
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
    return Scaffold(
      appBar: const NasabahPageAppBar(
        title: 'Bank sampah saya',
        showBack: true,
      ),
      body: SafeArea(
        child: Column(children: [
          TabBar(controller: _tabController, tabs: const [
            Tab(text: 'Bank Diikuti'),
            Tab(text: 'Riwayat pengajuan'),
          ]),
          Expanded(
            child: !_ownerDataReady
                ? ListView(
                    children: List.generate(
                        3,
                        (_) => const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: SkeletonListItem(),
                            )))
                : _loadFailed || state is NasabahApprovalError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PanelEmptyState(
                            title: 'Gagal Memuat Data',
                            message: state is NasabahApprovalError
                                ? state.message
                                : 'Coba periksa koneksi Anda.',
                          ),
                          AppButton(label: 'Coba lagi', onPressed: _reload),
                        ],
                      )
                    : state is NasabahApprovalLoaded
                        ? _membershipContent(state.memberships, activeId)
                        : const SizedBox.shrink(),
          ),
        ]),
      ),
    );
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

    return TabBarView(controller: _tabController, children: [
      ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (followed.isEmpty)
            const _PanelEmptyState(
              title: 'Belum ada bank yang diikuti',
              message: 'Bank yang disetujui akan muncul di sini.',
            ),
          for (final membership in followed) ...[
            _MembershipRow(
              membership: membership,
              isActive: membership.id == activeId,
              history: false,
              onTap: membership.dapatDibuka
                  ? () => _openBankDetail(membership)
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
      ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          KeyedSubtree(
            key: _historyKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      history: true,
                      onTap: () => _openHistoryDetail(membership),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (memberships.isNotEmpty)
            AppButton(
              label: 'Ajukan bank baru',
              icon: Icons.add,
              variant: AppButtonVariant.outlined,
              isLoading: _applying,
              onPressed: _applying ? null : _apply,
            ),
        ],
      ),
    ]);
  }

  Future<void> _openBankDetail(NasabahMembershipEntity membership) async {
    if (!_ownsCurrentSession() || !isSelectableMembership(membership)) return;
    final pageContext = context;
    await showAdaptiveSurface<void>(context, builder: (surfaceContext) {
      final detail = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!DialogSurface.of(surfaceContext)) const AppSheetHandle(),
          AppPanelHeader(
            title: 'Detail Bank Sampah',
            onClose: DialogSurface.of(surfaceContext)
                ? () => Navigator.of(surfaceContext).pop()
                : null,
          ),
          Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(authenticationProvider);
              if (!_sameOwner(widget.owner, authState) ||
                  !isSelectableMembership(membership)) {
                return const Text('Sesi berubah. Tutup dan masuk kembali.');
              }
              final active = ref.watch(activeMembershipProvider);
              return NasabahResource<NasabahBank>(
                load: () {
                  if (!_ownsCurrentSession() ||
                      !isSelectableMembership(membership)) {
                    throw StateError('Bank detail is no longer available.');
                  }
                  return di<NasabahRepository>().bank(membership.id);
                },
                builder: (context, bank) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NasabahBankDetail(bank: bank),
                    if (!active.isLoading &&
                        membership.id != active.value &&
                        isSelectableMembership(membership))
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: _MakeMembershipActiveButton(
                          membership: membership,
                          owner: widget.owner,
                          onSuccess: () {
                            if (mounted &&
                                pageContext.mounted &&
                                _ownsCurrentSession()) {
                              Navigator.of(surfaceContext).pop();
                              pageContext.go('/dashboard');
                            }
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      );
      return DialogSurface.of(surfaceContext)
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl), child: detail)
          : AppSheetContainer(child: detail);
    });
  }
}

class _MakeMembershipActiveButton extends ConsumerStatefulWidget {
  const _MakeMembershipActiveButton({
    required this.membership,
    required this.owner,
    required this.onSuccess,
  });

  final NasabahMembershipEntity membership;
  final AuthEntity owner;
  final VoidCallback onSuccess;

  @override
  ConsumerState<_MakeMembershipActiveButton> createState() =>
      _MakeMembershipActiveButtonState();
}

class _MakeMembershipActiveButtonState
    extends ConsumerState<_MakeMembershipActiveButton> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _select() async {
    if (_saving ||
        !isSelectableMembership(widget.membership) ||
        !_sameOwner(widget.owner, ref.read(authenticationProvider))) {
      return;
    }
    setState(() {
      _saving = true;
      _failed = false;
    });
    final saved = await ref
        .read(activeMembershipProvider.notifier)
        .select(widget.membership.id);
    if (!mounted ||
        !_sameOwner(widget.owner, ref.read(authenticationProvider))) {
      return;
    }
    if (!saved) {
      setState(() {
        _saving = false;
        _failed = true;
      });
      return;
    }
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: _failed ? 'Coba lagi' : 'Jadikan bank aktif',
            isLoading: _saving,
            onPressed: _saving ? null : _select,
          ),
          if (_failed)
            Text('Pilihan belum tersimpan. Bank aktif tidak berubah.',
                style: AppTextStyle.small.copyWith(color: AppColors.danger)),
        ],
      );
}

class _MembershipRow extends StatefulWidget {
  const _MembershipRow({
    required this.membership,
    required this.isActive,
    required this.history,
    required this.onTap,
  });

  final NasabahMembershipEntity membership;
  final bool isActive;
  final bool history;
  final Future<void> Function()? onTap;

  @override
  State<_MembershipRow> createState() => _MembershipRowState();
}

class _MembershipRowState extends State<_MembershipRow> {
  bool _opened = false;

  Future<void> _open() async {
    final action = widget.onTap;
    if (action == null) return;
    setState(() => _opened = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _opened = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = widget.membership;
    final isActive = widget.isActive;
    final history = widget.history;
    final onTap = widget.onTap;
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
        if (history || onTap != null)
          AnimatedRotation(
            turns: _opened ? .5 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.expand_more, color: AppColors.inkSoft),
          )
        else if (unavailable)
          const SizedBox(width: AppSpacing.sm),
      ]),
    );
    final content = onTap == null
        ? row
        : AppTapTarget(
            onTap: _open,
            label: history
                ? 'Lihat detail pengajuan ke ${membership.bankSampahNama}'
                : 'Detail ${membership.bankSampahNama}',
            selected: isActive,
            child: row,
          );
    return content;
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
