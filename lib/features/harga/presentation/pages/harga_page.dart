import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_table.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/master_detail_layout.dart';
import 'package:pilah_mobile/design/layout/web_pagination_bar.dart';
import 'package:pilah_mobile/design/layout/page_state_view.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/design/widgets/app_tappable_card.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_detail_flow.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/jenis_sampah_form.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';

class HargaPage extends StatelessWidget {
  const HargaPage({super.key, this.isWeb = kIsWeb});

  static const route = '/harga';
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return _HargaPageBody(isWeb: isWeb);
  }
}

class _HargaPageBody extends StatefulWidget {
  const _HargaPageBody({required this.isWeb});
  final bool isWeb;

  @override
  State<_HargaPageBody> createState() => _HargaPageBodyState();
}

class _HargaPageBodyState extends State<_HargaPageBody> {
  /// Jenis sampah yang sedang dibuka di panel, atau null bila tidak ada.
  HargaEntity? _editing;

  /// Panel terbuka dalam mode tambah.
  ///
  /// Dipisahkan dari [_editing] karena "tambah" tidak punya item: tanpa penanda
  /// sendiri, panel tambah tidak dapat dibedakan dari panel tertutup.
  bool _creating = false;

  /// Jenis sampah yang detailnya terbuka di panel, atau null.
  ///
  /// Mengetuk baris membuka detail, bukan form: edit dan riwayat harga adalah
  /// pilihan di dalamnya. Detail, form, dan riwayat bergantian di panel yang
  /// sama, sehingga tabel tetap terlihat.
  HargaEntity? _viewing;
  int _currentPage = 1;

  static const _webPageSize = 10;
  static const _pageTitle = 'Jenis Sampah & Harga';
  static const _addLabel = 'Tambah Jenis Sampah';

  bool get _isPanelOpen => _creating || _editing != null || _viewing != null;

  HargaEntity? get _selected => _editing ?? _viewing;

  @override
  void initState() {
    super.initState();
    context.read<HargaCubit>().loadHarga();
  }

  /// Menutup panel ketika jendela berhenti menjadi expanded.
  ///
  /// [_openForm] memilih wadah sekali, saat dibuka, tetapi lebar jendela dapat
  /// berubah setelah itu. Tanpa ini panel yang sudah terbuka akan ikut
  /// mengecil ke lebar yang justru dihindari, dan pada compact
  /// [MasterDetailLayout] melepas detail sama sekali sehingga form dibuang
  /// sementara halaman masih mengira ada panel terbuka. Pelajaran ini datang
  /// dari review PIL-339 (PR #113), yang menemukan persis masalah itu di
  /// layar jadwal.
  ///
  /// `MediaQuery` dibaca sebagai dependensi, jadi method ini ikut terpanggil
  /// setiap kali ukuran jendela berubah. Field diubah langsung tanpa setState
  /// karena build selalu menyusul.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isPanelOpen && context.layoutBreakpoint != LayoutBreakpoint.expanded) {
      _editing = null;
      _creating = false;
      _viewing = null;
    }
  }

  /// Membuka form untuk [item], atau untuk jenis sampah baru bila null.
  ///
  /// Hanya expanded yang mendapat panel, mengikuti layar jadwal: pada medium
  /// panel hanya mendapat dua dari lima bagian lebar, sekitar 320 piksel, dan
  /// form ini berisi dropdown, pemilih tanggal, ringkasan harga, serta
  /// peringatan BR-03 yang tidak muat di sana. Di bawah expanded bottom sheet
  /// tetap wadah yang lebih baik.
  void _openForm([HargaEntity? item]) {
    if (context.layoutBreakpoint == LayoutBreakpoint.expanded) {
      setState(() {
        _editing = item;
        _creating = item == null;
        _viewing = null;
      });
      return;
    }

    final hargaCubit = context.read<HargaCubit>();
    showAdaptiveSurface<void>(
      context,
      builder: (_) => TambahJenisSampahBottomSheet(
        hargaCubit: hargaCubit,
        initialData: item,
      ),
    );
  }

  /// Membuka detail [item]: di panel samping pada expanded, di bottom sheet di
  /// bawahnya. Mengedit dan melihat riwayat harga adalah dua pilihan di dalam
  /// detail itu.
  void _openDetail(HargaEntity item) {
    if (context.layoutBreakpoint == LayoutBreakpoint.expanded) {
      setState(() {
        _viewing = item;
        _editing = null;
        _creating = false;
      });
      return;
    }
    showAdaptiveSurface<void>(
      context,
      builder: (sheetContext) => HargaDetailFlow(
        item: item,
        onEdit: () {
          Navigator.of(sheetContext).pop();
          _openForm(item);
        },
      ),
    );
  }

  void _closePanel() {
    if (!_isPanelOpen) return;
    setState(() {
      _editing = null;
      _creating = false;
      _viewing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HargaCubit, HargaState>(
      listenWhen: (previous, current) =>
          widget.isWeb &&
          current is HargaLoaded &&
          (previous is! HargaLoaded ||
              !identical(previous.jenisSampahList, current.jenisSampahList)),
      listener: (context, state) {
        if (_currentPage != 1) setState(() => _currentPage = 1);
      },
      child: Scaffold(
        // Mengikuti warna permukaan shell web (6d094ba8); di telepon tetap
        // putih karena di sana halaman ini bukan isi sebuah shell.
        backgroundColor:
            WebContentSurface.pageColor(context, phone: Colors.white),
        // Hanya di telepon. Di layar lebar tombol tambah ada di kepala halaman,
        // seperti tabel nasabah, sehingga tidak ada yang melayang di atas
        // tombol "Simpan Perubahan" milik panel.
        floatingActionButton:
            context.layoutBreakpoint != LayoutBreakpoint.compact || widget.isWeb
                ? null
                : FloatingActionButton(
                    heroTag: 'harga_page_fab',
                    tooltip: _addLabel,
                    onPressed: () => _openForm(),
                    backgroundColor: AppColors.greenDark,
                    elevation: 4,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
        body: SafeArea(
          child: MasterDetailLayout(
            master: _buildList(),
            detail: _isPanelOpen ? _buildPanel() : null,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final web = context.layoutBreakpoint != LayoutBreakpoint.compact;
    final search = CustomSearchField(
      hintText: 'Cari jenis sampah...',
      onChanged: (value) {
        context.read<HargaCubit>().searchHarga(value);
      },
    );
    return Padding(
      padding: web
          ? const EdgeInsets.symmetric(horizontal: AppSpacing.webGutter)
          : const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: web ? AppSpacing.webTop : 16),
          if (web)
            AppPageHeader(
              title: _pageTitle,
              search: search,
              actions: [
                AppButton(
                  label: _addLabel,
                  icon: Icons.add,
                  expand: false,
                  onPressed: _openForm,
                ),
              ],
            )
          else if (widget.isWeb)
            AppPageHeader(
              title: _pageTitle,
              search: search,
              actions: [
                IconButton(
                  tooltip: _addLabel,
                  onPressed: _openForm,
                  icon: const Icon(Icons.add, color: AppColors.greenDark),
                ),
              ],
            )
          else ...[
            Text(
              _pageTitle,
              style: AppTextStyle.headline1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            search,
          ],
          const SizedBox(height: 16),
          BlocBuilder<HargaCubit, HargaState>(
            buildWhen: (previous, current) {
              if (previous is HargaLoaded && current is HargaLoaded) {
                return previous.isActiveTab != current.isActiveTab;
              }
              return true;
            },
            builder: (context, state) {
              final isActiveTab =
                  state is HargaLoaded ? state.isActiveTab : true;
              return Row(
                children: [
                  AppChip(
                    label: 'Aktif',
                    selected: isActiveTab,
                    onTap: () => context.read<HargaCubit>().setActiveTab(true),
                  ),
                  const SizedBox(width: 8),
                  AppChip(
                    label: 'Tidak Aktif',
                    selected: !isActiveTab,
                    onTap: () => context.read<HargaCubit>().setActiveTab(false),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: () =>
                  context.read<HargaCubit>().loadHarga(silent: true),
              child: BlocBuilder<HargaCubit, HargaState>(
                builder: (context, state) => _buildStateView(state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Keempat kondisi halaman lewat [PageStateView], bukan rangkaian `if` yang
  /// dituliskan sendiri: PRD 6.2.5 mewajibkan loading, kosong, dan gagal
  /// ditangani, dan widget itu sudah mengumpulkannya di satu tempat.
  Widget _buildStateView(HargaState state) {
    final loaded = state is HargaLoaded ? state : null;
    final items = loaded?.jenisSampahList ?? const <HargaEntity>[];

    final pageState = switch (state) {
      HargaError() => PageState.error,
      HargaLoaded() => items.isEmpty ? PageState.empty : PageState.ready,
      // Initial dihitung sebagai loading: pemuatan pertama sudah dijadwalkan
      // di initState, jadi layar kosong di sini hanya berarti belum sampai.
      _ => PageState.loading,
    };

    final isSearching = loaded?.searchQuery.isNotEmpty ?? false;
    final isActiveTab = loaded?.isActiveTab ?? true;

    final empty = _emptyState(
      isSearching: isSearching,
      isActiveTab: isActiveTab,
    );
    final listBottomPadding = widget.isWeb
        ? const EdgeInsets.only(bottom: 16)
        : const EdgeInsets.only(bottom: 80);
    final visibleItems = widget.isWeb
        ? items
            .skip((_currentPage - 1) * _webPageSize)
            .take(_webPageSize)
            .toList()
        : items;
    final wide = context.layoutBreakpoint != LayoutBreakpoint.compact;
    final pagination = WebPaginationBar(
      currentPage: _currentPage,
      totalItems: items.length,
      pageSize: _webPageSize,
      itemLabel: 'jenis sampah',
      onPageChanged: (page) => setState(() => _currentPage = page),
    );
    final Widget cards = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: listBottomPadding,
      itemCount: visibleItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = visibleItems[index];
        return _HargaCard(
          item: item,
          selected: _selected?.id == item.id,
          onTap: () => _openDetail(item),
        );
      },
    );
    final Widget content = wide
        ? Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: HargaTable(
              items: visibleItems,
              selectedId: _selected?.id,
              onTap: _openDetail,
              // Paginasi di dasar kartu, seperti tabel nasabah.
              footer: widget.isWeb ? pagination : null,
            ),
          )
        : widget.isWeb
            // Browser sempit: kartu satu kolom, paginasi di bawahnya.
            ? Column(
                children: [
                  Expanded(child: cards),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.xl,
                    ),
                    child: pagination,
                  ),
                ],
              )
            : cards;

    return PageStateView(
      state: pageState,
      onRetry: () => context.read<HargaCubit>().loadHarga(),
      errorMessage: state is HargaError ? state.message : null,
      emptyTitle: empty.title,
      emptySubtitle: empty.subtitle,
      emptyIcon: empty.icon,
      child: content,
    );
  }

  /// Judul, penjelasan, dan ikon untuk daftar yang kosong.
  ///
  /// Satu cabang per keadaan, bukan tiga ternary bersarang yang berjalan
  /// sejajar: ketiga nilai itu harus menggambarkan keadaan yang sama, dan
  /// memisahkannya membuat salah satu mudah tertinggal saat yang lain diubah.
  ({String title, String subtitle, IconData icon}) _emptyState({
    required bool isSearching,
    required bool isActiveTab,
  }) {
    if (isSearching) {
      return (
        title: 'Jenis Sampah Tidak Ditemukan',
        subtitle: 'Coba kata kunci yang berbeda',
        icon: Icons.search_off,
      );
    }
    if (isActiveTab) {
      return (
        title: 'Belum Ada Jenis Sampah',
        subtitle: 'Tekan tombol + untuk menambah jenis sampah.',
        icon: Icons.category_outlined,
      );
    }
    return (
      title: 'Tidak Ada Jenis Nonaktif',
      subtitle: 'Semua jenis sampah masih aktif.',
      icon: Icons.check_circle_outline,
    );
  }

  /// Panel form di samping daftar.
  ///
  /// Memakai [BottomSheetHeader] dengan [onClose], bukan judul sendiri: header
  /// itu sudah menyediakan cara menutup selain mem-pop route, tepat untuk panel
  /// yang berada inline di dalam body. Pegangan tarik dimatikan karena panel
  /// tidak dapat ditarik.
  Widget _buildPanel() {
    final viewing = _viewing;
    final Widget content;
    if (viewing != null) {
      content = HargaDetailFlow(
        item: viewing,
        embedded: true,
        onClose: _closePanel,
        onEdit: () => _openForm(viewing),
      );
    } else {
      final editing = _editing;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPanelHeader(
            title: JenisSampahForm.titleFor(editing),
            subtitle: editing?.name,
            // Edit dibuka dari detail, jadi ada jalan kembali ke sana.
            onBack: editing == null ? null : () => _openDetail(editing),
            onClose: _closePanel,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: JenisSampahForm(
                initialData: editing,
                onSaved: _closePanel,
              ),
            ),
          ),
        ],
      );
    }
    // Esc menutup panel dari mana pun fokusnya berada di dalamnya.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _closePanel,
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Satu baris daftar harga.
///
/// Dipisahkan menjadi widget sendiri supaya [selected] punya tempat: pada
/// jendela expanded baris yang sedang dibuka di panel perlu terlihat, kalau
/// tidak isi panel tidak jelas milik baris yang mana.
class _HargaCard extends StatelessWidget {
  const _HargaCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final HargaEntity item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final terjadwal = item.hargaTerjadwal;

    final card = AppTappableCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, color: AppColors.inkSoft),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.headline3.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.small.copyWith(color: AppColors.grey100),
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomStatusBadge(statusText: item.badgeText),
                if (terjadwal != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${CurrencyFormatter.formatRupiah(terjadwal.harga)} mulai '
                    '${formatTanggalId(terjadwal.berlakuMulai.toLocal())}',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // The price is what the pengurus came for, so it is the largest
          // text on the card and stays level with the name.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.priceFormatted,
                style: AppTextStyle.title1.copyWith(color: AppColors.black),
              ),
              Text(
                'per kg',
                style:
                    AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
              ),
            ],
          ),
        ],
      ),
    );

    if (!selected) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.greenDark, width: 2),
      ),
      child: card,
    );
  }
}
