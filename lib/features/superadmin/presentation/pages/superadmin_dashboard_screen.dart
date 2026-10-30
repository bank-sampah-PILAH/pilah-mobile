import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/proof_image_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/widgets/account_deletion_request.dart';
import 'package:pilah_mobile/features/superadmin/domain/entities/bank_sampah_entity.dart';
import 'package:pilah_mobile/features/superadmin/presentation/providers/superadmin_provider.dart';
import 'package:pilah_mobile/features/superadmin/presentation/states/superadmin_state.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

const List<String> _monthsId = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des'
];

String _formatDate(DateTime? date, {String prefix = ''}) {
  if (date == null) return '$prefix-';
  return '$prefix${date.day} ${_monthsId[date.month - 1]} ${date.year}';
}

/// The grey line under a card's title: the most specific location on record.
///
/// Used by the approved and rejected cards, which list no address row — without
/// this they would show no location at all. The pending card deliberately omits
/// it and relies on its full address row instead.
///
/// `kota` is an optional column that the registration form never fills. The form
/// has no city input — its address field asks for the city inline ("Jl. Nama
/// Jalan, RT/RW, Kelurahan, Kecamatan, Kota") — so anything registered from the
/// app arrives with `kota` empty and the city sitting inside `alamat`. Hence the
/// fallback, and hence no 'Kota tidak dicantumkan' placeholder: that reported
/// missing data on every real submission, when nothing was missing at all.
///
/// Returns null when there is genuinely nothing to show, so the caller drops the
/// line instead of printing a placeholder.
String? _locationLabel(BankSampahEntity bank) {
  final kota = bank.kota.trim();
  if (kota.isNotEmpty) return kota;
  final alamat = bank.alamat.trim();
  return alamat.isNotEmpty ? alamat : null;
}

/// Renders [_locationLabel], or occupies no space at all when there is none.
class _LocationLine extends StatelessWidget {
  final BankSampahEntity bank;

  const _LocationLine(this.bank);

  @override
  Widget build(BuildContext context) {
    final label = _locationLabel(bank);
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            const TextStyle(fontSize: AppFontSize.sm, color: AppColors.grey100),
      ),
    );
  }
}

int _waitingDays(DateTime? date) {
  if (date == null) return 0;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final submission = DateTime(date.year, date.month, date.day);
  return today.difference(submission).inDays;
}

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  static const route = '/superadmin-dashboard';

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  String _activeTab = 'Menunggu';

  static const Map<String, String> _tabStatus = {
    'Menunggu': 'pending',
    'Disetujui': 'active',
    'Ditolak': 'rejected',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(superadminProvider.notifier).loadBankSampah('pending');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationProvider, (previous, state) {
      if (state is Unauthenticated) context.go('/login');
    });
    return Scaffold(
      backgroundColor: AppColors.fill,
      body: Column(
        children: [
          _buildHeader(context),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: AccountDeletionRequestButton(),
          ),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: () => ref
                  .read(superadminProvider.notifier)
                  .loadBankSampah(_tabStatus[_activeTab]!, silent: true),
              child: _buildContentArea(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SuperAdmin PILAH',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: AppFontSize.sm),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manajemen Bank Sampah',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.xxl,
                        fontWeight: AppFontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () => ProviderScope.containerOf(context, listen: false)
                    .read(authenticationProvider.notifier)
                    .logout(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child:
                      const Icon(Icons.logout, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tabStatus.keys
                  .map((label) => _buildTab(context, label))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: AppChip.onColor(
        label: label,
        selected: _activeTab == label,
        onTap: () {
          if (_activeTab == label) return;
          setState(() => _activeTab = label);
          ref
              .read(superadminProvider.notifier)
              .loadBankSampah(_tabStatus[label]!);
        },
      ),
    );
  }

  Widget _buildContentArea() {
    final state = ref.watch(superadminProvider);
    if (state is SuperadminLoading || state is SuperadminInitial) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => const SkeletonListItem(),
      );
    }

    if (state is SuperadminError) {
      return EmptyView(
        title: 'Gagal Memuat Data',
        subtitle: state.message,
        icon: Icons.error_outline,
      );
    }

    if (state is SuperadminLoaded) {
      if (state.banks.isEmpty) return _buildEmptyState(state.status);
      final actions = ref.read(superadminProvider.notifier);
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: state.banks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, index) {
          final bank = state.banks[index];
          switch (state.status) {
            case 'active':
              return ApprovedBankCard(bank: bank);
            case 'rejected':
              return RejectedBankCard(bank: bank);
            default:
              return PendingBankCard(bank: bank, actions: actions);
          }
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(String status) {
    late final IconData icon;
    late final String title;
    late final String subtitle;
    switch (status) {
      case 'active':
        icon = Icons.verified_outlined;
        title = 'Belum Ada yang Disetujui';
        subtitle = 'Bank sampah yang disetujui akan muncul di sini.';
        break;
      case 'rejected':
        icon = Icons.cancel_outlined;
        title = 'Belum Ada Penolakan';
        subtitle =
            'Pendaftaran yang ditolak akan tercatat di sini sebagai arsip.';
        break;
      default:
        icon = Icons.inbox_outlined;
        title = 'Tidak Ada Pengajuan';
        subtitle = 'Semua pendaftaran bank sampah sudah ditinjau.';
    }
    return EmptyView(title: title, subtitle: subtitle, icon: icon);
  }
}

class PendingBankCard extends StatefulWidget {
  final BankSampahEntity bank;
  final SuperadminActions actions;

  const PendingBankCard({super.key, required this.bank, required this.actions});

  @override
  State<PendingBankCard> createState() => _PendingBankCardState();
}

class _PendingBankCardState extends State<PendingBankCard> {
  bool _isProcessing = false;

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required bool destructive,
  }) async {
    return showAppConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
  }

  Future<void> _runAction({required bool approve}) async {
    final bank = widget.bank;
    // Captured before any await so notifications can survive this card being
    // rebuilt away when the list reloads on success.
    final overlayContext = Navigator.of(context, rootNavigator: true).context;

    final confirmed = await _confirm(
      title: approve ? 'Setujui Bank Sampah?' : 'Tolak Pendaftaran?',
      message: approve
          ? 'Setujui pendaftaran ${bank.nama}? Bank sampah akan dapat mulai beroperasi.'
          : 'Tolak pendaftaran ${bank.nama}? Pengurus tidak dapat mengakses dashboard.',
      confirmLabel: approve ? 'Ya, Setujui' : 'Ya, Tolak',
      destructive: !approve,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
    final error = approve
        ? await widget.actions.approve(bank.id)
        : await widget.actions.reject(bank.id);

    if (error != null && mounted) {
      setState(() => _isProcessing = false);
    }
    if (!overlayContext.mounted) return;
    _showActionResult(overlayContext, bank, approve, error);
  }

  void _showActionResult(
    BuildContext context,
    BankSampahEntity bank,
    bool approve,
    NetworkException? error,
  ) {
    if (error != null) {
      AppNotification.showError(
        context,
        title: 'Gagal',
        message: error.displayMessage,
      );
      return;
    }
    AppNotification.showSuccess(
      context,
      title: approve ? 'Disetujui' : 'Ditolak',
      message: approve
          ? '${bank.nama} berhasil disetujui.'
          : 'Pendaftaran ${bank.nama} telah ditolak.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    return _CardShell(
      accentColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: bank.nama,
            badgeText: 'PENDING',
            badgeBg: AppColors.warningLight,
            badgeFg: AppColors.warning,
          ),
          // No location line here on purpose: the full address is listed in the
          // detail rows below, so a city above it is redundant.
          const SizedBox(height: 12),
          _infoRow(
              Icons.person_outline, '${bank.pengelolaNama ?? '-'} (Ketua)'),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, bank.alamat),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined,
              _formatDate(bank.createdAt, prefix: 'Diajukan: ')),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time_outlined,
              'Menunggu: ${_waitingDays(bank.createdAt)} hari',
              isBold: true),
          const SizedBox(height: 16),
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.greenDark),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Lihat Bukti',
                    variant: AppButtonVariant.tonal,
                    size: AppButtonSize.compact,
                    icon: Icons.image_outlined,
                    onPressed: () => showProofImageDialog(context,
                        imageUrl: bank.fotoKegiatan),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Setujui',
                    size: AppButtonSize.compact,
                    icon: Icons.check,
                    onPressed: () => _runAction(approve: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Tolak',
                    variant: AppButtonVariant.destructiveOutlined,
                    size: AppButtonSize.compact,
                    icon: Icons.close,
                    onPressed: () => _runAction(approve: false),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ApprovedBankCard extends StatelessWidget {
  final BankSampahEntity bank;

  const ApprovedBankCard({super.key, required this.bank});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      accentColor: AppColors.greenDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: bank.nama,
            badgeText: 'AKTIF',
            badgeBg: AppColors.greenLight,
            badgeFg: AppColors.greenDark,
            badgeIcon: Icons.check_box,
          ),
          // Falls back to the address: unlike the pending card, this one shows
          // no address row, so without it an app-registered bank has no
          // location on screen at all.
          _LocationLine(bank),
          const SizedBox(height: 12),
          _infoRow(
              Icons.person_outline, '${bank.pengelolaNama ?? '-'} (Ketua)'),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined,
              _formatDate(bank.createdAt, prefix: 'Terdaftar: ')),
        ],
      ),
    );
  }
}

class RejectedBankCard extends StatelessWidget {
  final BankSampahEntity bank;

  const RejectedBankCard({super.key, required this.bank});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      accentColor: AppColors.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: bank.nama,
            badgeText: 'DITOLAK',
            badgeBg: AppColors.dangerLight,
            badgeFg: AppColors.danger,
          ),
          _LocationLine(bank),
          const SizedBox(height: 12),
          _infoRow(
              Icons.person_outline, '${bank.pengelolaNama ?? '-'} (Ketua)'),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined,
              _formatDate(bank.createdAt, prefix: 'Diajukan: ')),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const _CardShell({required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(AppRadius.lg),
                ),
              ),
            ),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(16.0), child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final String badgeText;
  final Color badgeBg;
  final Color badgeFg;
  final IconData? badgeIcon;

  const _CardHeader({
    required this.title,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeFg,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: AppFontWeight.bold,
                color: AppColors.black),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeIcon != null) ...[
                Icon(badgeIcon, color: badgeFg, size: 12),
                const SizedBox(width: 4),
              ],
              Text(
                badgeText,
                style: TextStyle(
                    color: badgeFg,
                    fontSize: AppFontSize.xs,
                    fontWeight: AppFontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _infoRow(IconData icon, String text, {bool isBold = false}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: isBold ? AppColors.black : AppColors.grey100),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: AppFontSize.sm,
            color: isBold ? AppColors.black : AppColors.grey100,
            fontWeight: isBold ? AppFontWeight.bold : AppFontWeight.regular,
          ),
        ),
      ),
    ],
  );
}
