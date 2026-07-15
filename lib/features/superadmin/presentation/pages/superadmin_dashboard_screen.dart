import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/proof_image_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/superadmin/domain/entities/bank_sampah_entity.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_cubit.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_state.dart';
import 'package:pilah_mobile/services/di.dart';

const List<String> _monthsId = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
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
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
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

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  static const route = '/superadmin-dashboard';

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  String _activeTab = 'Menunggu';

  static const Map<String, String> _tabStatus = {
    'Menunggu': 'pending',
    'Disetujui': 'active',
    'Ditolak': 'rejected',
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<SuperadminCubit>()..loadBankSampah('pending'),
      child: Builder(
        builder: (context) => BlocListener<AuthenticationBloc, AuthenticationStates>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              context.go('/login');
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF3F4F6),
            body: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: AppRefreshIndicator(
                    // Reloads the tab currently on screen, not whichever status
                    // the cubit happens to have loaded last.
                    onRefresh: () => context
                        .read<SuperadminCubit>()
                        .loadBankSampah(_tabStatus[_activeTab]!, silent: true),
                    child: _buildContentArea(),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
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
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manajemen Bank Sampah',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.read<AuthenticationBloc>().add(LogoutRequested()),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout, color: Colors.white, size: 20),
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

  // Takes the context explicitly: the SuperadminCubit is provided by the
  // BlocProvider inside build(), so the surrounding State's own context sits
  // above it and cannot resolve the cubit.
  Widget _buildTab(BuildContext context, String label) {
    final isActive = _activeTab == label;
    return GestureDetector(
      onTap: () {
        if (_activeTab == label) return;
        setState(() => _activeTab = label);
        context.read<SuperadminCubit>().loadBankSampah(_tabStatus[label]!);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.greenDark : Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    return BlocBuilder<SuperadminCubit, SuperadminState>(
      builder: (context, state) {
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
          if (state.banks.isEmpty) {
            return _buildEmptyState(state.status);
          }
          final cubit = context.read<SuperadminCubit>();
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
                  return PendingBankCard(bank: bank, cubit: cubit);
              }
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
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
        subtitle = 'Pendaftaran yang ditolak akan tercatat di sini sebagai arsip.';
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
  final SuperadminCubit cubit;

  const PendingBankCard({super.key, required this.bank, required this.cubit});

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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive ? Colors.red : AppColors.greenDark,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
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
          : 'Tolak pendaftaran ${bank.nama}? Pengelola tidak dapat mengakses dashboard.',
      confirmLabel: approve ? 'Ya, Setujui' : 'Ya, Tolak',
      destructive: !approve,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);
    final error =
        approve ? await widget.cubit.approve(bank.id) : await widget.cubit.reject(bank.id);

    if (error != null) {
      if (mounted) setState(() => _isProcessing = false);
      if (overlayContext.mounted) {
        AppNotification.showError(overlayContext, title: 'Gagal', message: error.displayMessage);
      }
      return;
    }
    if (overlayContext.mounted) {
      AppNotification.showSuccess(
        overlayContext,
        title: approve ? 'Disetujui' : 'Ditolak',
        message: approve
            ? '${bank.nama} berhasil disetujui.'
            : 'Pendaftaran ${bank.nama} telah ditolak.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    return _CardShell(
      accentColor: const Color(0xFFF59E0B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: bank.nama,
            badgeText: 'PENDING',
            badgeBg: const Color(0xFFFEF3C7),
            badgeFg: const Color(0xFFD97706),
          ),
          // No location line here on purpose: the full address is listed in the
          // detail rows below, so a city above it is redundant.
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, '${bank.pengelolaNama ?? '-'} (Ketua)'),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, bank.alamat),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined, _formatDate(bank.createdAt, prefix: 'Diajukan: ')),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time_outlined, 'Menunggu: ${_waitingDays(bank.createdAt)} hari', isBold: true),
          const SizedBox(height: 16),
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.greenDark),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => showProofImageDialog(context, imageUrl: bank.fotoKegiatan),
                    icon: const Icon(Icons.image_outlined, size: 14, color: AppColors.greenDark),
                    label: const Text('Lihat Bukti',
                        style: TextStyle(fontSize: 12, color: AppColors.greenDark, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenLight,
                      foregroundColor: AppColors.greenDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _runAction(approve: true),
                    icon: const Icon(Icons.check, size: 14, color: Colors.white),
                    label: const Text('Setujui',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _runAction(approve: false),
                    icon: const Icon(Icons.close, size: 14, color: Colors.red),
                    label: const Text('Tolak',
                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
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
            badgeBg: Colors.green.shade100,
            badgeFg: AppColors.greenDark,
            badgeIcon: Icons.check_box,
          ),
          // Falls back to the address: unlike the pending card, this one shows
          // no address row, so without it an app-registered bank has no
          // location on screen at all.
          _LocationLine(bank),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, '${bank.pengelolaNama ?? '-'} (Ketua)'),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined, _formatDate(bank.createdAt, prefix: 'Terdaftar: ')),
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
      accentColor: Colors.red.shade400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: bank.nama,
            badgeText: 'DITOLAK',
            badgeBg: Colors.red.shade50,
            badgeFg: Colors.red.shade600,
          ),
          _LocationLine(bank),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, '${bank.pengelolaNama ?? '-'} (Ketua)'),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined, _formatDate(bank.createdAt, prefix: 'Diajukan: ')),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
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
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeIcon != null) ...[
                Icon(badgeIcon, color: badgeFg, size: 12),
                const SizedBox(width: 4),
              ],
              Text(
                badgeText,
                style: TextStyle(color: badgeFg, fontSize: 10, fontWeight: FontWeight.bold),
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
      Icon(icon, size: 16, color: isBold ? Colors.black87 : Colors.grey.shade500),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isBold ? Colors.black87 : Colors.grey.shade600,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    ],
  );
}
