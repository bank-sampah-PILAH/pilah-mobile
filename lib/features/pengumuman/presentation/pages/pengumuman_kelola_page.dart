import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/back_header_row.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_state.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_form_page.dart';

/// The filter chips of the manage screen: derived statuses come straight from
/// the backend's `?status=`, and '' means no filter.
const _filterOptions = <String, String>{
  'Semua': '',
  'Draft': 'draft',
  'Terjadwal': 'terjadwal',
  'Terbit': 'terbit',
  'Kedaluwarsa': 'kedaluwarsa',
  'Ditarik': 'ditarik',
};

/// Pengurus manage screen (PIL-332): one list of the bank's announcements with
/// the status filter and per-row actions — edit drafts and scheduled rows,
/// cancel a schedule, withdraw a published one, delete drafts. Kedaluwarsa and
/// ditarik rows are read-only.
class PengumumanKelolaPage extends StatelessWidget {
  const PengumumanKelolaPage({super.key});

  static const route = '/pengumuman/kelola';

  @override
  Widget build(BuildContext context) {
    return BlocListener<PengumumanCubit, PengumumanState>(
      listener: (context, state) {
        if (state is PengumumanError) {
          AppNotification.showError(context,
              title: 'Gagal', message: state.message);
        }
      },
      child: const _PengumumanKelolaBody(),
    );
  }
}

class _PengumumanKelolaBody extends StatefulWidget {
  const _PengumumanKelolaBody();

  @override
  State<_PengumumanKelolaBody> createState() => _PengumumanKelolaBodyState();
}

class _PengumumanKelolaBodyState extends State<_PengumumanKelolaBody> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadNextPageNearEnd);
    context.read<PengumumanCubit>().loadPengumuman();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPageNearEnd)
      ..dispose();
    super.dispose();
  }

  void _loadNextPageNearEnd() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 320) {
      return;
    }
    context.read<PengumumanCubit>().loadNextPage();
  }

  PengumumanCubit get _cubit => context.read<PengumumanCubit>();

  Future<void> _bukaForm([PengumumanEntity? pengumuman]) async {
    final router = GoRouter.of(context);
    await router.push(
      PengumumanFormPage.route,
      extra: PengumumanFormArgs(pengumuman: pengumuman),
    );
    // The form reloads the list after a successful save; tapping out without
    // saving leaves the list as it is.
  }

  Future<bool> _konfirmasi({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) =>
      showAppConfirmDialog(
        context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: destructive,
      );

  void _laporkan(String suksesTitle, String suksesMessage, String? failure) {
    // Two frames first: the confirm dialog just popped, and raising the toast
    // in the same frame collides with the navigator it is closing.
    AppNotification.afterNavigation((toastContext) {
      if (failure != null) {
        AppNotification.showError(toastContext,
            title: 'Gagal', message: failure);
      } else {
        AppNotification.showSuccess(toastContext,
            title: suksesTitle, message: suksesMessage);
      }
    });
  }

  Future<void> _batalkanJadwal(PengumumanEntity pengumuman) async {
    if (!await _konfirmasi(
      title: 'Batalkan jadwal?',
      message: '"${pengumuman.judul}" kembali menjadi draft dan tidak akan '
          'terbit secara terjadwal.',
      confirmLabel: 'Batalkan',
    )) {
      return;
    }
    // The form does the update; a null terbit_pada is the backend's
    // cancel-schedule PATCH (PIL-332).
    final result = await _cubit.savePengumuman(PengumumanEntity(
      id: pengumuman.id,
      bankSampahId: pengumuman.bankSampahId,
      judul: pengumuman.judul,
      isi: pengumuman.isi,
      masaBerlakuHingga: pengumuman.masaBerlakuHingga,
      status: pengumuman.status,
    ));
    final errorMessage = result.fold(
      (theFailure) => theFailure.displayMessage,
      (_) => null,
    );
    _laporkan('Jadwal dibatalkan', 'Kembali menjadi draft.', errorMessage);
  }

  Future<void> _tarik(PengumumanEntity pengumuman) async {
    if (!await _konfirmasi(
      title: 'Tarik pengumuman?',
      message:
          '"${pengumuman.judul}" berhenti tampil untuk semua nasabah Anda.',
      confirmLabel: 'Tarik',
    )) {
      return;
    }
    final failure = await _cubit.tarik(pengumuman.id);
    _laporkan(
        'Ditarik', 'Pengumuman berhenti tampil.', failure?.displayMessage);
  }

  Future<void> _hapusDraft(PengumumanEntity pengumuman) async {
    if (!await _konfirmasi(
      title: 'Hapus draft?',
      message: '"${pengumuman.judul}" dihapus permanen.',
      confirmLabel: 'Hapus',
      destructive: true,
    )) {
      return;
    }
    final failure = await _cubit.deletePengumuman(pengumuman.id);
    _laporkan('Terhapus', 'Draft pengumuman dihapus.', failure?.displayMessage);
  }

  @override
  Widget build(BuildContext context) {
    // Same page shape as the Riwayat Aktivitas (Laporan) screen: white page,
    // fixed header + filter block, scrollable feed under it (no AppBar, the
    // header row carries the back button like aktivitas'.
    return BlocListener<PengumumanCubit, PengumumanState>(
      listener: (context, state) {
        if (state is PengumumanError) {
          AppNotification.showError(context,
              title: 'Gagal', message: state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _bukaForm,
          backgroundColor: AppColors.greenDark,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Buat',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const BackHeaderRow(title: 'Kelola Pengumuman'),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _FilterChips(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<PengumumanCubit, PengumumanState>(
                  builder: (context, state) {
                    switch (state) {
                      case PengumumanInitial _:
                      case PengumumanLoading _:
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: 5,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              const SkeletonListItem(),
                        );
                      case PengumumanError state:
                        return Column(
                          children: [
                            Expanded(
                              child: EmptyView(
                                title: 'Gagal Memuat Data',
                                subtitle: state.message,
                                icon: Icons.error_outline,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _cubit.loadPengumuman(),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        );
                      case PengumumanLoaded loaded:
                        return _daftar(loaded);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _daftar(PengumumanLoaded loaded) {
    if (loaded.items.isEmpty) {
      // Without the filter it is a real zero state; with one, it reads as "no
      // announcement matches this bucket".
      final filtered = loaded.statusFilter.isNotEmpty;
      return EmptyView(
        title: filtered
            ? 'Tidak ada pengumuman dengan status ini'
            : 'Belum ada pengumuman',
        subtitle: filtered
            ? 'Coba filter status lain.'
            : 'Buat pengumuman untuk nasabah bank sampah Anda.',
        icon:
            filtered ? Icons.filter_alt_off_outlined : Icons.campaign_outlined,
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: loaded.items.length + (loaded.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= loaded.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _KelolaRow(
                key: ValueKey('pengumuman-kelola-${loaded.items[index].id}'),
                pengumuman: loaded.items[index],
                onUbah: _bukaForm,
                onBatalkanJadwal: _batalkanJadwal,
                onTarik: _tarik,
                onHapus: _hapusDraft,
              );
            },
          ),
        ),
        if (loaded.loadingMoreError != null) ...[
          Text(loaded.loadingMoreError!,
              style: AppTextStyle.small.copyWith(color: AppColors.danger)),
        ],
      ],
    );
  }
}

class _KelolaRow extends StatelessWidget {
  const _KelolaRow({
    super.key,
    required this.pengumuman,
    required this.onUbah,
    required this.onBatalkanJadwal,
    required this.onTarik,
    required this.onHapus,
  });

  final PengumumanEntity pengumuman;
  final ValueChanged<PengumumanEntity> onUbah;
  final void Function(PengumumanEntity) onBatalkanJadwal;
  final void Function(PengumumanEntity) onTarik;
  final void Function(PengumumanEntity) onHapus;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pengumuman.judul,
                  style: AppTextStyle.title1.copyWith(color: Colors.black),
                ),
              ),
              _StatusBadge(status: pengumuman.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pengumuman.isi,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.small.copyWith(color: AppColors.grey100),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (pengumuman.isDraft) ...[
                _ActionPill(
                  label: 'Ubah',
                  color: AppColors.greenDark,
                  onTap: () => onUbah(pengumuman),
                ),
                const SizedBox(width: 8),
                _ActionPill(
                  label: 'Hapus',
                  color: AppColors.danger,
                  onTap: () => onHapus(pengumuman),
                ),
              ] else if (pengumuman.isTerjadwal) ...[
                _ActionPill(
                  label: 'Ubah',
                  color: AppColors.greenDark,
                  onTap: () => onUbah(pengumuman),
                ),
                const SizedBox(width: 8),
                _ActionPill(
                  label: 'Batalkan Jadwal',
                  color: AppColors.danger,
                  onTap: () => onBatalkanJadwal(pengumuman),
                ),
              ] else if (pengumuman.isTerbit) ...[
                _ActionPill(
                  label: 'Tarik',
                  color: AppColors.danger,
                  onTap: () => onTarik(pengumuman),
                ),
              ],
              // kedaluwarsa and ditarik are read-only.
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.color, this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label,
          style: AppTextStyle.small
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const warna = <String, (Color, Color)>{
      'draft': (AppColors.fill, AppColors.inkSoft),
      'terjadwal': (AppColors.greenLight, AppColors.greenDark),
      'terbit': (AppColors.greenLight, AppColors.greenDark),
      'kedaluwarsa': (AppColors.statOrangeLight, AppColors.warning),
      'ditarik': (AppColors.cardOffWhite, AppColors.grey100),
    };
    final (bg, fg) =
        warna[status] ?? (AppColors.greenLight, AppColors.greenDark);
    return CustomStatusBadge(
      statusText: switch (status) {
        'terjadwal' => 'Terjadwal',
        'terbit' => 'Terbit',
        'kedaluwarsa' => 'Kedaluwarsa',
        'ditarik' => 'Ditarik',
        _ => 'Draft',
      },
      backgroundColor: bg,
      textColor: fg,
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    final selected = context.select<PengumumanCubit, String>((cubit) =>
        cubit.state is PengumumanLoaded
            ? (cubit.state as PengumumanLoaded).statusFilter
            : '');
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in _filterOptions.entries) ...[
          AppChip(
            label: entry.key,
            selected: selected == entry.value,
            onTap: () => context
                .read<PengumumanCubit>()
                .loadPengumuman(status: entry.value),
// '' is the no-filter bucket; null keeps the current filter.
          ),
        ],
      ],
    );
  }
}
