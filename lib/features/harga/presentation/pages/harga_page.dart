import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/master_detail_layout.dart';
import 'package:pilah_mobile/design/layout/page_state_view.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/design/widgets/app_tappable_card.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/riwayat_harga_page.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/jenis_sampah_form.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';

class HargaPage extends StatelessWidget {
  const HargaPage({super.key});

  static const route = '/harga';

  @override
  Widget build(BuildContext context) {
    return const _HargaPageBody();
  }
}

class _HargaPageBody extends StatefulWidget {
  const _HargaPageBody();

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

  bool get _isPanelOpen => _creating || _editing != null;

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
      });
      return;
    }

    final hargaCubit = context.read<HargaCubit>();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TambahJenisSampahBottomSheet(
        hargaCubit: hargaCubit,
        initialData: item,
      ),
    );
  }

  void _closePanel() {
    if (!_isPanelOpen) return;
    setState(() {
      _editing = null;
      _creating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mengikuti warna permukaan shell web (6d094ba8); di telepon tetap
      // putih karena di sana halaman ini bukan isi sebuah shell.
      backgroundColor:
          WebContentSurface.pageColor(context, phone: Colors.white),
      // Disembunyikan selama panel terbuka: FAB melayang di sudut kanan bawah
      // jendela, yaitu tepat di atas tombol "Simpan Perubahan" milik panel,
      // sehingga tombol simpan tertutup sebagian. Panel hanya ada pada
      // expanded, jadi di bawah itu FAB tidak pernah hilang.
      floatingActionButton: _isPanelOpen
          ? null
          : FloatingActionButton(
              heroTag: 'harga_page_fab',
              tooltip: 'Tambah Jenis Sampah',
              onPressed: () => _openForm(),
              backgroundColor: AppColors.greenDark,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: SafeArea(
        child: ContentBounds(
          child: MasterDetailLayout(
            master: _buildList(),
            detail: _isPanelOpen ? _buildPanel() : null,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Jenis Sampah & Harga',
            style: AppTextStyle.headline1.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          CustomSearchField(
            hintText: 'Cari jenis sampah...',
            onChanged: (value) {
              context.read<HargaCubit>().searchHarga(value);
            },
          ),
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

    return PageStateView(
      state: pageState,
      onRetry: () => context.read<HargaCubit>().loadHarga(),
      errorMessage: state is HargaError ? state.message : null,
      emptyTitle: empty.title,
      emptySubtitle: empty.subtitle,
      emptyIcon: empty.icon,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _HargaCard(
            item: item,
            selected: _editing?.id == item.id,
            onTap: () => _openForm(item),
          );
        },
      ),
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
    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BottomSheetHeader(
              title: JenisSampahForm.titleFor(_editing),
              showDragHandle: false,
              onClose: _closePanel,
            ),
            const SizedBox(height: 16),
            JenisSampahForm(
              initialData: _editing,
              onSaved: _closePanel,
            ),
          ],
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
        children: [
          // Leading icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          // Middle content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyle.title1.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: AppTextStyle.extraSmall.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                CustomStatusBadge(
                  statusText: item.badgeText,
                  backgroundColor: Colors.blue[50],
                  textColor: Colors.blue[600],
                ),
                if (terjadwal != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${CurrencyFormatter.formatRupiah(terjadwal.harga)} mulai '
                    '${formatTanggalId(terjadwal.berlakuMulai.toLocal())}',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.avatarYellowText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                // Its own tap target: tapping elsewhere on the card still
                // opens the edit form.
                AppButton(
                  label: 'Riwayat harga',
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.compact,
                  expand: false,
                  onPressed: () =>
                      context.push(RiwayatHargaPage.route, extra: item),
                ),
              ],
            ),
          ),
          // Trailing content
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'HARGA BELI',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    item.priceFormatted,
                    style: AppTextStyle.title1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    ' / kg',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
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
