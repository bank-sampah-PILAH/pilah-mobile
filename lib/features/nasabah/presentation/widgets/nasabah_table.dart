import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/data_table_card.dart';
import 'package:pilah_mobile/design/layout/page_state_view.dart';
import 'package:pilah_mobile/design/layout/web_pagination_bar.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_approval_dialog.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_filter_chips.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';

/// Daftar nasabah untuk layar lebar: tabel, bukan kartu satu kolom.
///
/// Memakai [NasabahCubit] yang sama dengan layar telepon, jadi pencarian,
/// penyaring, paginasi, dan seluruh aturan ubah data tidak digandakan.
class NasabahTable extends StatelessWidget {
  static const headerKey = ValueKey('nasabah-table-header');

  const NasabahTable({super.key, this.isWeb = kIsWeb});

  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return ContentBounds(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.webGutter,
          AppSpacing.webTop,
          AppSpacing.webGutter,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: AppSpacing.lg),
            const _Toolbar(),
            const SizedBox(height: 16),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: _TableBody(isWeb: isWeb),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NasabahCubit>();
    return AppPageHeader(
      title: 'Daftar Nasabah',
      subtitle: BlocBuilder<NasabahCubit, NasabahState>(
        builder: (context, state) => Text('${cubit.activeCount} nasabah aktif'),
      ),
      search: CustomSearchField(
        hintText: 'Cari nama nasabah...',
        onChanged: cubit.searchNasabah,
      ),
      actions: [
        AppButton(
          label: 'Tambah Nasabah',
          icon: Icons.add,
          expand: false,
          onPressed: () => showAdaptiveSurface<void>(
            context,
            builder: (_) => const TambahNasabahBottomSheet(),
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NasabahCubit>();
    return Align(
      alignment: Alignment.centerLeft,
      child: BlocBuilder<NasabahCubit, NasabahState>(
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType ||
            (previous is NasabahLoaded &&
                current is NasabahLoaded &&
                previous.isActiveTab != current.isActiveTab),
        builder: (context, state) => NasabahFilterChips(
          activeTab: state is NasabahLoaded
              ? state.isActiveTab
              : state is NasabahLoading
                  ? state.isActiveTab
                  : cubit.isActiveTab,
          onTabChanged: cubit.setActiveTab,
        ),
      ),
    );
  }
}

class _TableBody extends StatelessWidget {
  const _TableBody({required this.isWeb});
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NasabahCubit, NasabahState>(
      builder: (context, state) {
        if (state is NasabahLoading || state is NasabahInitial) {
          return const _Skeleton();
        }
        if (state is NasabahError) {
          return PageStateView(
            state: PageState.error,
            errorMessage: state.message,
            onRetry: context.read<NasabahCubit>().loadNasabah,
            child: const SizedBox.shrink(),
          );
        }
        if (state is! NasabahLoaded) return const SizedBox.shrink();
        if (state.nasabahList.isEmpty) return _Empty(state: state);
        return _Loaded(state: state, isWeb: isWeb);
      },
    );
  }
}

/// Tabel dengan isi: kepala kolom, penanda muat ulang, dan daftar baris.
class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.isWeb});
  final NasabahLoaded state;
  final bool isWeb;

  /// Cubit sendiri yang menolak permintaan ganda dan permintaan setelah
  /// halaman terakhir, jadi di sini cukup memberi tahu.
  bool _onScroll(BuildContext context, ScrollNotification notification) {
    if (!isWeb &&
        state.hasMore &&
        !state.isLoadingMore &&
        _hampirUjung(notification)) {
      context.read<NasabahCubit>().loadMoreNasabah();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderRow(),
        const Divider(height: 1, color: AppColors.border),
        SizedBox(
          height: 2,
          child: state.isReloading
              ? const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.greenDark,
                  backgroundColor: AppColors.greenLight)
              : null,
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => _onScroll(context, notification),
            child: ListView.separated(
              itemCount: state.nasabahList.length + (isWeb ? 0 : 1),
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) =>
                  !isWeb && index == state.nasabahList.length
                      ? _Footer(state: state)
                      : _Row(nasabah: state.nasabahList[index]),
            ),
          ),
        ),
        if (isWeb)
          DataTableCardFooter(
            child: WebPaginationBar(
              currentPage: state.currentPage,
              totalItems: state.totalCount,
              pageSize: state.pageSize,
              itemLabel: 'nasabah',
              onPageChanged: context.read<NasabahCubit>().loadPage,
            ),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.state});
  final NasabahLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.searchQuery.isNotEmpty) {
      return const EmptyView(
        title: 'Nasabah Tidak Ditemukan',
        subtitle: 'Coba kata kunci yang berbeda',
        icon: Icons.search_off,
      );
    }
    return EmptyView(
      title: state.isMenungguTab
          ? 'Tidak Ada Pengajuan'
          : state.isActiveTab!
              ? 'Belum Ada Nasabah'
              : 'Tidak Ada Nasabah Nonaktif',
      subtitle: state.isMenungguTab
          ? 'Belum ada pengajuan keanggotaan yang menunggu persetujuan.'
          : state.isActiveTab!
              ? 'Tekan "Tambah Nasabah" untuk menambah nasabah pertama.'
              : 'Semua nasabah masih berstatus aktif.',
      icon: state.isMenungguTab
          ? Icons.hourglass_empty
          : state.isActiveTab!
              ? Icons.people_outline
              : Icons.person_off_outlined,
    );
  }
}

/// Jarak dari dasar daftar saat halaman berikutnya mulai diambil; sama dengan
/// daftar di telepon.
const _ambangMuat = 200.0;

bool _hampirUjung(ScrollNotification notification) {
  final metrics = notification.metrics;
  if (!metrics.hasContentDimensions) return false;
  return metrics.pixels >= metrics.maxScrollExtent - _ambangMuat;
}

const _columns = <int>[5, 2, 3, 2, 2, 4];

/// Jarak antara kolom saldo (rata kanan) dan status, supaya tidak menempel.
const _gutter = 32.0;

TextStyle get _headStyle => AppTextStyle.small.copyWith(
    color: AppColors.grey100, fontWeight: FontWeight.w600, letterSpacing: 0.3);

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    Widget cell(int i, String text, {TextAlign align = TextAlign.start}) =>
        Expanded(
            flex: _columns[i],
            child: Text(text, style: _headStyle, textAlign: align));
    return DataTableCard.head(key: NasabahTable.headerKey, [
      cell(0, 'NASABAH'),
      cell(1, 'ID'),
      cell(2, 'NO. HP'),
      Expanded(
          flex: _columns[3],
          child: Padding(
              padding: const EdgeInsets.only(right: _gutter),
              child:
                  Text('SALDO', style: _headStyle, textAlign: TextAlign.end))),
      cell(4, 'STATUS'),
      cell(5, '', align: TextAlign.end),
    ]);
  }
}

class _Row extends StatefulWidget {
  const _Row({required this.nasabah});
  final NasabahEntity nasabah;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  NasabahEntity get n => widget.nasabah;
  bool get _pending => n.status == 'pending';
  String get _idUntukApi => n.id.isNotEmpty ? n.id : n.idNasabah;

  Future<void> _decide(bool reject) async {
    final cubit = context.read<NasabahCubit>();
    final overlay = Navigator.of(context, rootNavigator: true).context;
    final catatan = await showNasabahApprovalDialog(context,
        isApproving: !reject, customerName: n.name);
    if (catatan == null) return;
    final error = await cubit.decideNasabah(_idUntukApi,
        approve: !reject, catatan: catatan);
    if (overlay.mounted && error != null) {
      AppNotification.showError(overlay,
          title: 'Gagal', message: error.displayMessage);
    }
  }

  void _open() => showAdaptiveSurface<void>(
        context,
        builder: (_) => DetailNasabahBottomSheet(
            nasabah: n, nasabahCubit: context.read<NasabahCubit>()),
      );

  @override
  Widget build(BuildContext context) {
    final muted = !n.isActive && !_pending;
    final base = AppTextStyle.small
        .copyWith(color: muted ? AppColors.grey100 : AppColors.black);
    return MouseRegion(
      cursor: _pending ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: _pending ? null : _open,
        child: Container(
          color: _hover ? AppColors.greenLight.withValues(alpha: 0.45) : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(children: [
            Expanded(
              flex: _columns[0],
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: n.avatarColor,
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Text(n.initials,
                      style: AppTextStyle.small.copyWith(
                          color: n.textColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: base.copyWith(fontWeight: FontWeight.w600)),
                      if (n.email.isNotEmpty)
                        Text(n.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: base.copyWith(color: AppColors.grey100)),
                    ],
                  ),
                ),
              ]),
            ),
            Expanded(
                flex: _columns[1],
                child: Text(n.idNasabah,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: base)),
            Expanded(
                flex: _columns[2],
                child: Text(n.phone.isEmpty ? '-' : n.phone, style: base)),
            Expanded(
                flex: _columns[3],
                child: Padding(
                    padding: const EdgeInsets.only(right: _gutter),
                    child: Text(n.balance,
                        textAlign: TextAlign.end,
                        style: base.copyWith(
                            fontWeight: FontWeight.w600,
                            color: muted
                                ? AppColors.grey100
                                : AppColors.greenDark)))),
            Expanded(
              flex: _columns[4],
              child: Align(
                alignment: Alignment.centerLeft,
                child: _pending
                    ? const CustomStatusBadge(
                        statusText: 'Menunggu',
                        backgroundColor: AppColors.warningLight,
                        textColor: AppColors.warning)
                    : CustomStatusBadge(isActive: n.isActive),
              ),
            ),
            Expanded(
              flex: _columns[5],
              child: Align(
                alignment: Alignment.centerRight,
                child: _pending
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          AppButton(
                            label: 'Tolak',
                            variant: AppButtonVariant.destructiveOutlined,
                            size: AppButtonSize.compact,
                            expand: false,
                            onPressed: () => _decide(true),
                          ),
                          const SizedBox(width: 8),
                          AppButton(
                            label: 'Setujui',
                            size: AppButtonSize.compact,
                            expand: false,
                            onPressed: () => _decide(false),
                          ),
                        ]))
                    : AppButton(
                        label: 'Lihat detail',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.compact,
                        expand: false,
                        onPressed: _open,
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});
  final NasabahLoaded state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.isLoadingMore) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: 'Memuat nasabah berikutnya',
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
              'Menampilkan ${state.nasabahList.length} dari ${state.totalCount}',
              style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
        width: w,
        height: 12,
        decoration: BoxDecoration(
            color: AppColors.fill, borderRadius: BorderRadius.circular(6)));
    return Column(children: [
      const _HeaderRow(),
      const Divider(height: 1),
      for (var i = 0; i < 6; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(children: [
            Expanded(
                flex: 5,
                child: Align(alignment: Alignment.centerLeft, child: bar(180))),
            Expanded(
                flex: 2,
                child: Align(alignment: Alignment.centerLeft, child: bar(60))),
            Expanded(
                flex: 3,
                child: Align(alignment: Alignment.centerLeft, child: bar(100))),
            Expanded(
                flex: 2,
                child: Align(alignment: Alignment.centerRight, child: bar(70))),
            Expanded(
                flex: 2,
                child: Align(alignment: Alignment.centerLeft, child: bar(50))),
            const Spacer(flex: 3),
          ]),
        ),
    ]);
  }
}
