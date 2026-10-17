import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Kelola Pengumuman',
            style: AppTextStyle.title1.copyWith(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        backgroundColor: AppColors.greenDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: BlocBuilder<PengumumanCubit, PengumumanState>(
        builder: (context, state) {
          switch (state) {
            case PengumumanInitial _:
            case PengumumanLoading _:
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SkeletonListItem(),
                  SizedBox(height: 12),
                  SkeletonListItem(),
                  SizedBox(height: 12),
                  SkeletonListItem(),
                ],
              );
            case PengumumanError _:
              return Center(
                child: SingleChildScrollView(child: Text(state.message)),
              );
            case PengumumanLoaded loaded:
              return Column(
                children: [
                  _FilterChips(
                    selected: loaded.statusFilter,
                    onSelect: (value) => _cubit.loadPengumuman(
                        status: value.isEmpty ? null : value),
                  ),
                  Expanded(child: _daftar(loaded)),
                ],
              );
          }
        },
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
                OutlinedButton(
                  onPressed: () => onUbah(pengumuman),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: const BorderSide(color: AppColors.greenDark),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Ubah',
                      style: AppTextStyle.small.copyWith(
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => onHapus(pengumuman),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Hapus',
                      style: AppTextStyle.small.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                ),
              ] else if (pengumuman.isTerjadwal) ...[
                OutlinedButton(
                  onPressed: () => onUbah(pengumuman),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: const BorderSide(color: AppColors.greenDark),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Ubah',
                      style: AppTextStyle.small.copyWith(
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => onBatalkanJadwal(pengumuman),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Batalkan Jadwal',
                      style: AppTextStyle.small.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                ),
              ] else if (pengumuman.isTerbit) ...[
                OutlinedButton(
                  onPressed: () => onTarik(pengumuman),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Tarik',
                      style: AppTextStyle.small.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
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
  const _FilterChips({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          for (final entry in _filterOptions.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.key),
                selected: selected == entry.value,
                showCheckmark: false,
                selectedColor: AppColors.greenDark,
                labelStyle: TextStyle(
                  color:
                      selected == entry.value ? Colors.white : AppColors.black,
                ),
                onSelected: (_) => onSelect(entry.value),
              ),
            ),
        ],
      ),
    );
  }
}
