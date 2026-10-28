import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/core/bases/widgets/back_header_row.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/master_detail_layout.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/states/pengumuman_state.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/pengumuman_provider.dart';
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
/// Judul halaman, dipakai oleh setiap bentuk headernya.
const _judul = 'Kelola Pengumuman';

class PengumumanKelolaPage extends StatelessWidget {
  const PengumumanKelolaPage({super.key, this.isWeb = kIsWeb});

  final bool isWeb;

  static const route = '/pengumuman/kelola';

  @override
  Widget build(BuildContext context) => _PengumumanKelolaBody(isWeb: isWeb);
}

class _PengumumanKelolaBody extends ConsumerStatefulWidget {
  const _PengumumanKelolaBody({required this.isWeb});

  final bool isWeb;

  @override
  ConsumerState<_PengumumanKelolaBody> createState() =>
      _PengumumanKelolaBodyState();
}

class _PengumumanKelolaBodyState extends ConsumerState<_PengumumanKelolaBody> {
  late final ScrollController _scrollController;

  /// Halaman ini adalah cabang shell yang tetap hidup saat tab lain dibuka.
  /// Ia tidak dibangun ulang saat dibuka lagi, jadi daftarnya dimuat ulang
  /// ketika cabangnya kembali aktif.
  bool _active = true;
  bool _panelOpen = false;
  PengumumanEntity? _panelInitial;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadNextPageNearEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pengumumanProvider.notifier).loadPengumuman();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_panelOpen &&
        (!widget.isWeb ||
            context.layoutBreakpoint != LayoutBreakpoint.expanded)) {
      _panelOpen = false;
      _panelInitial = null;
    }
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(pengumumanProvider.notifier).loadPengumuman(silent: true);
        }
      });
    }
    _active = active;
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
    ref.read(pengumumanProvider.notifier).loadNextPage();
  }

  PengumumanNotifier get _notifier => ref.read(pengumumanProvider.notifier);

  Future<void> _bukaForm([PengumumanEntity? pengumuman]) async {
    if (widget.isWeb && context.layoutBreakpoint == LayoutBreakpoint.expanded) {
      setState(() {
        _panelOpen = true;
        _panelInitial = pengumuman;
      });
      return;
    }

    final router = GoRouter.of(context);
    await router.push(
      PengumumanFormPage.route,
      extra: PengumumanFormArgs(pengumuman: pengumuman),
    );
    // The form reloads the list after a successful save; tapping out without
    // saving leaves the list as it is.
  }

  void _tutupPanel() {
    setState(() {
      _panelOpen = false;
      _panelInitial = null;
    });
  }

  Widget? _buildFormPanel() {
    if (!_panelOpen) return null;
    return PengumumanFormPage(
      key: ValueKey('pengumuman-panel-${_panelInitial?.id ?? 'baru'}'),
      args: PengumumanFormArgs(pengumuman: _panelInitial),
      onClose: _tutupPanel,
    );
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
    final result = await _notifier.savePengumuman(PengumumanEntity(
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
    final failure = await _notifier.tarik(pengumuman.id);
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
    final failure = await _notifier.deletePengumuman(pengumuman.id);
    _laporkan('Terhapus', 'Draft pengumuman dihapus.', failure?.displayMessage);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pengumumanProvider, (previous, state) {
      if (state is PengumumanError) {
        AppNotification.showError(context,
            title: 'Gagal', message: state.message);
      }
    });
    final state = ref.watch(pengumumanProvider);
    final webHeader =
        widget.isWeb && context.layoutBreakpoint != LayoutBreakpoint.compact;
    // Same page shape as the Riwayat Aktivitas (Laporan) screen: white page,
    // fixed header + filter block, scrollable feed under it (no AppBar, the
    // header row carries the back button like aktivitas'.
    return Scaffold(
      backgroundColor: Colors.white,
      // Di web lebar tombol "Buat" ada di header halaman, seperti Nasabah dan
      // Harga; FAB hanya untuk layar sempit dan aplikasi.
      floatingActionButton: webHeader
          ? null
          : FloatingActionButton.extended(
              onPressed: _bukaForm,
              backgroundColor: AppColors.greenDark,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Buat',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
      body: SafeArea(
        child: MasterDetailLayout(
          masterScrolls: true,
          master: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContentInset(
                child: Padding(
                  padding: webHeader
                      ? const EdgeInsets.fromLTRB(AppSpacing.webGutter,
                          AppSpacing.webTop, AppSpacing.webGutter, 0)
                      : const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _header(webHeader: webHeader),
                ),
              ),
              SizedBox(height: webHeader ? AppSpacing.lg : 16),
              ContentInset(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: webHeader ? AppSpacing.webGutter : 16),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: _FilterChips(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _feed(context, state),
              ),
            ],
          ),
          detail: _buildFormPanel(),
        ),
      ),
    );
  }

  /// Judul halaman. Di web halaman ini adalah destinasi sidebar, jadi tidak
  /// ada yang perlu dikembalikan: header halaman di layar lebar, judul saja di
  /// browser sempit. Di aplikasi ia dibuka dari Profil dan kembali ke sana.
  Widget _header({required bool webHeader}) {
    if (webHeader) {
      return AppPageHeader(
        title: _judul,
        actions: [
          AppButton(
            label: 'Buat',
            icon: Icons.add,
            expand: false,
            onPressed: _bukaForm,
          ),
        ],
      );
    }
    if (widget.isWeb) {
      return Text(_judul,
          style: AppTextStyle.appBar.copyWith(color: AppColors.black));
    }
    return BackHeaderRow(
      title: _judul,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppLocations.profile),
    );
  }

  /// Daftar sesuai keadaan: memuat, gagal, atau terisi.
  Widget _feed(BuildContext context, PengumumanState state) {
    switch (state) {
      case PengumumanInitial _:
      case PengumumanLoading _:
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: _listPadding(context, bottom: 80),
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => const SkeletonListItem(),
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
              onPressed: () => _notifier.loadPengumuman(),
              child: const Text('Coba Lagi'),
            ),
          ],
        );
      case PengumumanLoaded loaded:
        return _daftar(loaded);
    }
  }

  /// Jarak samping daftar: gutter halaman, ditambah batas lebar dari
  /// `ContentFrame`, supaya scrollbar-nya di tepi jendela.
  EdgeInsets _listPadding(BuildContext context, {required double bottom}) {
    final gutter =
        widget.isWeb && context.layoutBreakpoint != LayoutBreakpoint.compact
            ? AppSpacing.webGutter
            : 16.0;
    return ContentFrame.insetOf(context) +
        EdgeInsets.fromLTRB(gutter, 8, gutter, bottom);
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
            padding: _listPadding(context, bottom: 96),
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                  style: AppTextStyle.title1.copyWith(color: AppColors.black),
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
                AppButton(
                  label: 'Ubah',
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.outlined,
                  expand: false,
                  onPressed: () => onUbah(pengumuman),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Hapus',
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.destructiveOutlined,
                  expand: false,
                  onPressed: () => onHapus(pengumuman),
                ),
              ] else if (pengumuman.isTerjadwal) ...[
                AppButton(
                  label: 'Ubah',
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.outlined,
                  expand: false,
                  onPressed: () => onUbah(pengumuman),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Batalkan Jadwal',
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.destructiveOutlined,
                  expand: false,
                  onPressed: () => onBatalkanJadwal(pengumuman),
                ),
              ] else if (pengumuman.isTerbit) ...[
                AppButton(
                  label: 'Tarik',
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.destructiveOutlined,
                  expand: false,
                  onPressed: () => onTarik(pengumuman),
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

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pengumumanProvider);
    final selected = state is PengumumanLoaded ? state.statusFilter : '';
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in _filterOptions.entries) ...[
          AppChip(
            label: entry.key,
            selected: selected == entry.value,
            onTap: () => ref
                .read(pengumumanProvider.notifier)
                .loadPengumuman(status: entry.value),
// '' is the no-filter bucket; null keeps the current filter.
          ),
        ],
      ],
    );
  }
}
