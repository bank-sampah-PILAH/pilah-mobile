import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/activity_item.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/web_pagination_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_summary_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_table.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_setoran_detail.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_detail_sheet.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/batalkan_setoran_dialog.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/edit_setoran_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/hold_to_select.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// Renders the merged setoran + pencairan feed (PIL-282), grouped by day.
/// Setoran rows expand inline; pencairan rows open their detail sheet with
/// Pengurus-only edit/riwayat-perubahan entry points.
/// Jarak area gulir daftar kartu di telepon: batas lebar dari `ContentFrame`
/// (nol di telepon) dan ruang di bawah baris terakhir.
EdgeInsetsGeometry _scrollPadding(BuildContext context,
        {required double bottom}) =>
    ContentFrame.insetOf(context).add(EdgeInsets.only(bottom: bottom));

class AktivitasListView extends StatelessWidget {
  final DateTime Function() now;
  final bool isWeb;

  const AktivitasListView({
    super.key,
    this.now = DateTime.now,
    this.isWeb = kIsWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) =>
          _buildState(context, ref.watch(riwayatAktivitasProvider)),
    );
  }

  Widget _buildState(BuildContext context, RiwayatAktivitasState state) {
    if (state.status == AktivitasStatus.initial ||
        state.status == AktivitasStatus.loading) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _scrollPadding(context, bottom: 80),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => const SkeletonListItem(),
      );
    }
    if (state.status == AktivitasStatus.failure) {
      return _buildFailure(context, state);
    }
    if (state.items.isEmpty) return _buildEmpty(state);
    return _buildLoaded(context, state);
  }

  Widget _buildFailure(BuildContext context, RiwayatAktivitasState state) {
    return Column(children: [
      Expanded(
        child: EmptyView(
          title: 'Gagal Memuat Data',
          subtitle: state.errorMessage ?? 'Terjadi kesalahan',
          icon: Icons.error_outline,
        ),
      ),
      TextButton(
        onPressed: () => ProviderScope.containerOf(context, listen: false)
            .read(riwayatAktivitasProvider.notifier)
            .load(),
        child: const Text('Coba Lagi'),
      ),
    ]);
  }

  Widget _buildEmpty(RiwayatAktivitasState state) {
    final searching = state.search.isNotEmpty;
    return EmptyView(
      title: searching ? 'Aktivitas Tidak Ditemukan' : 'Belum Ada Aktivitas',
      subtitle: searching
          ? 'Coba kata kunci atau nama pelanggan lain'
          : 'Belum ada aktivitas tercatat pada periode ini.',
      icon: Icons.receipt_long_outlined,
    );
  }

  Widget _buildLoaded(BuildContext context, RiwayatAktivitasState state) {
    final footer = _footer(context, state);
    if (context.layoutBreakpoint != LayoutBreakpoint.compact) {
      return _buildWideList(context, state, footer);
    }

    final cards = _withScrollNotifications(
      context,
      state,
      ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _scrollPadding(context, bottom: 24),
        children: _groupedRows(state, now(), footer),
      ),
    );
    if (!isWeb) return cards;
    // Browser sempit: kartu satu kolom, paginasi di bawahnya.
    return LayoutBuilder(
        builder: (context, constraints) => Column(
              children: [
                Expanded(child: cards),
                // While the nested header is still visible, large text can leave less
                // height than the pagination needs. Keep it scrollable until the user
                // scrolls the header away rather than overflowing that initial frame.
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                  child: SingleChildScrollView(
                    primary: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildPagination(context, state),
                    ),
                  ),
                ),
              ],
            ));
  }

  Widget _buildWideList(
    BuildContext context,
    RiwayatAktivitasState state,
    List<Widget> footer,
  ) {
    // Halaman data: tabel sebagai kartu yang mengisi sisa tinggi layar,
    // hanya barisnya yang bergulir, dan paginasi di dasar kartu.
    final side = ContentFrame.insetOf(context).add(
      const EdgeInsets.symmetric(horizontal: AppSpacing.webGutter),
    );
    return _withScrollNotifications(
      context,
      state,
      Padding(
        padding: side.add(const EdgeInsets.only(bottom: AppSpacing.xl)),
        child: Consumer(
            builder: (context, ref, _) => AktivitasTable(
                  selectedIds: ref.watch(aktivitasBulkSelectionProvider),
                  onToggleSelection:
                      ref.read(aktivitasBulkSelectionProvider.notifier).toggle,
                  items: state.items,
                  onTap: (item) => _openPencairanDetail(context, item),
                  loadSetoranDetail: (id) => ProviderScope.containerOf(
                    context,
                    listen: false,
                  ).read(transaksiProvider.notifier).fetchTransaksiDetail(id),
                  onEdit: (item) => _editItem(context, item),
                  // Hapus only shows on a tercatat setoran, which always has its record.
                  onHapus: (item) =>
                      showBatalkanSetoranDialog(context, item.transaksi!.id),
                  footer: footer,
                  toolbar: const AktivitasSummaryStrip(),
                  page: state.currentPage,
                  pagination: isWeb ? _buildPagination(context, state) : null,
                )),
      ),
    );
  }

  Future<void> _editItem(BuildContext context, ActivitasEntity item) async {
    final id = item.transaksi?.id;
    if (id == null || id.isEmpty) return;
    await showEditSetoranSheet(context, id);
  }

  Widget _buildPagination(
    BuildContext context,
    RiwayatAktivitasState state,
  ) {
    return WebPaginationBar(
      currentPage: state.currentPage,
      totalItems: state.totalCount,
      pageSize: state.pageSize,
      itemLabel: 'transaksi',
      onPageChanged: ProviderScope.containerOf(context, listen: false)
          .read(riwayatAktivitasProvider.notifier)
          .loadPage,
    );
  }

  Widget _withScrollNotifications(
    BuildContext context,
    RiwayatAktivitasState state,
    Widget child,
  ) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!isWeb &&
            notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 200 &&
            state.errorMessage == null) {
          ProviderScope.containerOf(context, listen: false)
              .read(riwayatAktivitasProvider.notifier)
              .loadMore();
        }
        return false;
      },
      child: child,
    );
  }

  /// Baris yang dikelompokkan per hari, untuk telepon.
  List<Widget> _groupedRows(
    RiwayatAktivitasState state,
    DateTime today,
    List<Widget> footer,
  ) {
    final children = <Widget>[];
    String? lastHeader;
    for (final item in state.items) {
      final header = _dayHeader(item.tanggal, today);
      if (header != lastHeader) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            header,
            style: AppTextStyle.extraSmall.copyWith(
              color: AppColors.grey100,
              fontWeight: AppFontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ));
        lastHeader = header;
      }
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _AktivitasRow(key: AktivitasTable.rowKey(item), item: item),
      ));
    }
    return [...children, ...footer];
  }

  /// Indikator muat atau tombol "Muat Lagi" di bawah baris terakhir.
  List<Widget> _footer(BuildContext context, RiwayatAktivitasState state) {
    if (state.loadingMore) {
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }
    if (isWeb && state.retryPage == null) return const [];
    if (!state.hasNext && state.retryPage == null) return const [];
    return [
      TextButton(
        onPressed: () {
          final cubit = ProviderScope.containerOf(context, listen: false)
              .read(riwayatAktivitasProvider.notifier);
          final retryPage = state.retryPage;
          if (retryPage == null) {
            cubit.loadMore();
          } else {
            cubit.loadPage(retryPage);
          }
        },
        child: Text(state.errorMessage == null ? 'Muat Lagi' : 'Coba Lagi'),
      ),
      if (state.errorMessage != null)
        Text(state.errorMessage!, textAlign: TextAlign.center),
    ];
  }

  String _dayHeader(DateTime? tanggal, DateTime today) {
    if (tanggal == null) return 'LAINNYA';
    final diff = DateUtils.dateOnly(today)
        .difference(DateUtils.dateOnly(tanggal))
        .inDays;
    if (diff <= 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return '$diff HARI LALU';
  }
}

/// Opens a payout's detail sheet with its Pengurus-only edit actions.
void _openPencairanDetail(BuildContext context, ActivitasEntity item) {
  showPencairanDetailSheet(
    context,
    item.pencairan!,
    onChanged: () => ProviderScope.containerOf(context, listen: false)
        .read(riwayatAktivitasProvider.notifier)
        .load(silent: true),
  );
}

class _AktivitasRow extends ConsumerStatefulWidget {
  const _AktivitasRow({super.key, required this.item});

  final ActivitasEntity item;

  @override
  ConsumerState<_AktivitasRow> createState() => _AktivitasRowState();
}

class _AktivitasRowState extends ConsumerState<_AktivitasRow> {
  static const _selectedBleed = 10.0;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final id = item.transaksi?.id ?? '';
    final expandable = item.tipe == ActivitasTipe.setoran;
    // A voided setoran is final: nothing to edit or cancel again.
    final selectable = item.isSelectableSetoran;
    final selection = ref.watch(aktivitasSelectionProvider);
    final bulkSelection = ref.watch(aktivitasBulkSelectionProvider);
    final selecting = selection != null || bulkSelection != null;
    final selected = selectable &&
        (selection == id || (bulkSelection?.contains(id) ?? false));

    return HoldToSelect(
      enabled: selectable && !selecting,
      bleed: _selectedBleed,
      onSelected: () => _select(id),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActivityRow(
                context,
                item,
                id,
                expandable,
                selectable,
                selecting,
                selected,
              ),
              if (expandable && bulkSelection == null) _buildDetails(id),
            ],
          ),
          if (selected) _selectedTint(),
          if (selected && bulkSelection == null) _selectionIndicator(),
        ],
      ),
    );
  }

  void _select(String id) {
    setState(() => _expanded = false);
    ref.read(aktivitasSelectionProvider.notifier).select(id);
  }

  Widget _buildActivityRow(
    BuildContext context,
    ActivitasEntity item,
    String id,
    bool expandable,
    bool selectable,
    bool selecting,
    bool selected,
  ) =>
      Semantics(
        button: true,
        expanded: expandable && _expanded,
        hint: _tapHint(selecting, expandable),
        child: InkWell(
          key: selected ? const ValueKey('aktivitas-row-selected') : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _handleTap(
            context,
            item,
            id,
            expandable,
            selectable,
            selecting,
          ),
          child: Row(
            children: [
              if (ref.watch(aktivitasBulkSelectionProvider) != null &&
                  selectable)
                Checkbox(
                  value: selected,
                  semanticLabel: 'Pilih setoran ${item.title}',
                  onChanged: (_) => ref
                      .read(aktivitasBulkSelectionProvider.notifier)
                      .toggle(id),
                ),
              Expanded(
                child: ActivityItem(
                  avatarText: item.avatarText,
                  avatarColor: item.avatarColor,
                  avatarTextColor: item.avatarTextColor,
                  title: item.title,
                  subtitleLines: item.subtitleLines,
                  amount: item.amount,
                  amountColor: item.amountColor,
                  trailingCaptions: item.trailingCaptions,
                  badge: item.badge,
                ),
              ),
              if (expandable && !selecting)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.grey100,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      );

  String? _tapHint(bool selecting, bool expandable) {
    if (selecting || !expandable) return null;
    return _expanded
        ? 'Ketuk untuk menutup rincian'
        : 'Ketuk untuk melihat rincian';
  }

  void _handleTap(
    BuildContext context,
    ActivitasEntity item,
    String id,
    bool expandable,
    bool selectable,
    bool selecting,
  ) {
    if (ref.read(aktivitasBulkSelectionProvider) != null) {
      if (selectable) {
        setState(() => _expanded = false);
        ref.read(aktivitasBulkSelectionProvider.notifier).toggle(id);
      }
      return;
    }
    if (selecting) {
      if (selectable) {
        ref.read(aktivitasSelectionProvider.notifier).toggle(id);
      }
      return;
    }
    if (expandable) {
      setState(() => _expanded = !_expanded);
    } else {
      _openPencairanDetail(context, item);
    }
  }

  Widget _buildDetails(String id) => AnimatedSize(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: _expanded
            ? AktivitasSetoranDetail(
                key: ValueKey('setoran-details-$id'),
                transactionId: id,
                loadDetail: (id) => ref
                    .read(transaksiProvider.notifier)
                    .fetchTransaksiDetail(id),
              )
            : const SizedBox.shrink(),
      );

  Widget _selectedTint() => Positioned(
        top: 0,
        bottom: 0,
        left: -_selectedBleed,
        right: -_selectedBleed,
        child: IgnorePointer(
          child: DecoratedBox(
            key: const ValueKey('aktivitas-row-selected-tint'),
            decoration: BoxDecoration(
              color: AppColors.greenDark.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.greenDark, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      );

  Widget _selectionIndicator() => const Positioned(
        top: 6,
        left: 6 - _selectedBleed,
        child: CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.greenDark,
          child: Icon(Icons.check, color: Colors.white, size: 14),
        ),
      );
}
