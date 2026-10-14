import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/core/utils/formatter/jarak_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_cubit.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_state.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/widgets/peta_bank_view.dart';
import 'package:pilah_mobile/features/map/presentation/pages/map_picker_page.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/services/di.dart';

/// Pencarian bank sampah untuk calon nasabah (PIL-308): kata kunci + kota
/// (placeholder PIL-329 opsi A), paged by the backend.
class CariBankPage extends StatelessWidget {
  static const route = '/cari-bank-sampah';

  const CariBankPage({super.key, this.tileLayerBuilder});

  /// Test seam threaded to the map mode (PIL-330); null = the real OSM layer.
  final Widget Function()? tileLayerBuilder;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => di<CariBankCubit>(),
        child: CariBankView(tileLayerBuilder: tileLayerBuilder),
      );
}

class CariBankView extends StatefulWidget {
  const CariBankView({super.key, this.tileLayerBuilder});

  final Widget Function()? tileLayerBuilder;

  @override
  State<CariBankView> createState() => _CariBankViewState();
}

class _CariBankViewState extends State<CariBankView> {
  /// Daftar first: the map is the fancy view, not the default reading flow.
  String _mode = 'Daftar';
  @override
  void initState() {
    super.initState();
    context.read<CariBankCubit>().load();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CariBankCubit, CariBankState>(
        builder: (context, state) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Cari Bank Sampah',
              style: AppTextStyle.appBar.copyWith(color: NasabahStyle.ink),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            scrolledUnderElevation: 0,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: CustomSearchField(
                  key: const Key('cari_bank_kata_kunci'),
                  hintText: 'Cari nama, alamat, atau kota...',
                  onChanged: context.read<CariBankCubit>().ketikKataKunci,
                ),
              ),
              // Satu kolom pencarian: q mencocokkan nama + alamat + kota
              // di backend, jadi kolom kota terpisah tidak diperlukan.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _ModeSwitch(
                  key: const Key('cari_bank_mode'),
                  mode: _mode,
                  dekatSaya: () =>
                      context.read<CariBankCubit>().pilihLokasiSaya(),
                  pilihDiPeta: () =>
                      _pilihDiPeta(context, widget.tileLayerBuilder),
                  onPilih: (mode) => setState(() => _mode = mode),
                  tampilkanLokasi:
                      state is CariBankLoaded && state.dalamRadiusKm == null,
                ),
              ),
              // Radius aktif: chips 1/5/10/25 km + keluar dari mode lokasi.
              if (state is CariBankLoaded && state.dalamRadiusKm != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final km in const [1.0, 5.0, 10.0, 25.0])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _RadiusChip(
                              key: Key('cari_bank_radius_${km.toInt()}'),
                              label: '${km.toInt()} km',
                              dipilih: km == state.dalamRadiusKm,
                              onTap: () => context
                                  .read<CariBankCubit>()
                                  .pilihRadiusKm(km),
                            ),
                          ),
                        _RadiusChip(
                          key: const Key('cari_bank_hapus_lokasi'),
                          label: 'Hapus lokasi',
                          icon: Icons.close,
                          dipilih: false,
                          onTap: () =>
                              context.read<CariBankCubit>().hapusLokasi(),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(child: _CariBankBody(state: state)),
            ],
          ),
        ),
      );
}

/// Dua pintu masuk titik lokasi (PIL-314): perangkat sekarang atau titik yang
/// dipilih di peta (MapPickerPage — bukan rute go_router, pola Navigator push).
Future<void> _pilihDiPeta(
  BuildContext context,
  Widget Function()? tileLayerBuilder,
) async {
  final titik = await Navigator.of(context, rootNavigator: true)
      .push<({double latitude, double longitude})>(
    MaterialPageRoute(
      builder: (_) => tileLayerBuilder == null
          ? const MapPickerPage()
          : MapPickerPage(tileLayerBuilder: tileLayerBuilder),
    ),
  );
  if (titik != null && context.mounted) {
    context.read<CariBankCubit>().pilihDariPeta(titik);
  }
}

class _CariBankBody extends StatelessWidget {
  final CariBankState state;

  const _CariBankBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    // Body reads the view's mode through the enclosing state widget.
    final view = context.findAncestorStateOfType<_CariBankViewState>()!;
    if (state is CariBankError) {
      return Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 280,
            child: EmptyView(
              title: 'Gagal Memuat Bank Sampah',
              subtitle: state.message,
              icon: Icons.wifi_off_outlined,
            ),
          ),
          TextButton.icon(
            key: const Key('cari_bank_coba_lagi'),
            onPressed: context.read<CariBankCubit>().load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
          ),
          const Spacer(),
        ],
      );
    }

    if (state is CariBankLoading || state is CariBankInitial) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: 5,
        itemBuilder: (context, index) => const SkeletonListItem(),
      );
    }

    final loaded = state as CariBankLoaded;
    if (loaded.items.isEmpty) {
      return EmptyView(
        title: 'Bank Tidak Ditemukan',
        subtitle: loaded.searchQuery.isEmpty && loaded.kotaFilter.isEmpty
            ? 'Belum ada bank sampah terdaftar.'
            : 'Tidak ada bank yang cocok dengan pencarian.',
        icon: Icons.search_off,
      );
    }
    if (view._mode == 'Peta' &&
        // Peta mode shows only banks a marker can stand on; banks without
        // coordinates stay list-only (PIL-330).
        !loaded.items.any((bank) => bank.lokasi != null)) {
      return const EmptyView(
        title: 'Tidak Ada Bank Dengan Lokasi',
        subtitle: 'Bank yang dipilih tidak memasang koordinat di peta.',
        icon: Icons.map_outlined,
      );
    }
    if (view._mode == 'Peta') {
      return PetaBankView(
        banks: loaded.items,
        tileLayerBuilder: view.widget.tileLayerBuilder,
      );
    }
    return _DaftarBank(loaded: loaded);
  }
}

class _DaftarBank extends StatelessWidget {
  final CariBankLoaded loaded;

  const _DaftarBank({required this.loaded});

  /// Jarak dari dasar daftar saat halaman berikutnya mulai diambil, supaya
  /// datanya sudah siap sebelum pengguna benar-benar sampai ke ujung.
  static const double _ambangMuat = 200;

  bool _hampirUjung(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (!metrics.hasContentDimensions) return false;
    return metrics.pixels >= metrics.maxScrollExtent - _ambangMuat;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CariBankCubit>();
    return AppRefreshIndicator(
      onRefresh: () => cubit.load(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (loaded.hasMore &&
              !loaded.isLoadingMore &&
              _hampirUjung(notification)) {
            cubit.muatBerikutnya();
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: loaded.items.length + (loaded.hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == loaded.items.length) {
              // Ujung daftar: pemuat halaman berikutnya, atau diam.
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: loaded.isLoadingMore
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }
            return _BankTile(bank: loaded.items[index]);
          },
        ),
      ),
    );
  }
}

/// Kartu bank — pola [NasabahListItem]: avatar inisial, nama tegas, sub
/// kota/alamat, jarak sebagai tag hijau di kanan.
class _BankTile extends StatelessWidget {
  final BankSampahDirectoryEntity bank;

  const _BankTile({required this.bank});

  String get _initials => bank.nama
      .split(RegExp(r'\s+'))
      .where((kata) => kata.isNotEmpty)
      .take(2)
      .map((kata) => kata[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final sub = '${bank.kota} · ${bank.alamat}';
    return GestureDetector(
      onTap: () => context.push(
        BankSampahDetailPage.route,
        extra: bank.id,
      ),
      child: Container(
        key: Key('cari_bank_row_${bank.id}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: AppTextStyle.title1.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank.nama,
                    style: AppTextStyle.title1.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: AppTextStyle.small.copyWith(
                      color: Colors.grey[400],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (bank.jarakKm != null) ...[
              const SizedBox(width: 8),
              PillTag(text: formatJarakId(double.parse(bank.jarakKm!))),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tag kecil bentuk pil untuk satu label pendek (jarak, mode, dsb.).
class PillTag extends StatelessWidget {
  final String text;

  const PillTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: AppTextStyle.extraSmall.copyWith(
            color: AppColors.greenDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

/// Satu baris kontrol: Daftar/Peta + (saat berlaku) dua pintu lokasi —
/// dekat-saya (ikon) dan pilih-titik-di-peta (ikon). Empat tombol jadi satu
/// baris kecil supaya pilihan jelas.
class _ModeSwitch extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onPilih;
  final VoidCallback dekatSaya;
  final VoidCallback pilihDiPeta;
  final bool tampilkanLokasi;

  const _ModeSwitch({
    super.key,
    required this.mode,
    required this.onPilih,
    required this.dekatSaya,
    required this.pilihDiPeta,
    required this.tampilkanLokasi,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _ModePill(
              label: 'Daftar',
              icon: Icons.list_outlined,
              dipilih: mode == 'Daftar',
              onTap: () => onPilih('Daftar'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModePill(
              label: 'Peta',
              icon: Icons.map_outlined,
              dipilih: mode == 'Peta',
              onTap: () => onPilih('Peta'),
            ),
          ),
          if (tampilkanLokasi) ...[
            const SizedBox(width: 8),
            _IkonAksi(
              key: const Key('cari_bank_dekat_saya'),
              icon: Icons.near_me_outlined,
              pesan: 'Di dekat saya',
              onTap: dekatSaya,
            ),
            const SizedBox(width: 8),
            _IkonAksi(
              key: const Key('cari_bank_pilih_di_peta'),
              icon: Icons.travel_explore_outlined,
              pesan: 'Pilih titik pencarian di peta',
              onTap: pilihDiPeta,
            ),
          ],
        ],
      );
}

/// Tombol ikon bulat hijau muda untuk aksi lokasi.
class _IkonAksi extends StatelessWidget {
  final IconData icon;
  final String pesan;
  final VoidCallback onTap;

  const _IkonAksi({
    super.key,
    required this.icon,
    required this.pesan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: pesan,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppColors.greenDark),
          ),
        ),
      );
}

/// Pil Daftar/Peta bertema hijau (pola nasabah_filter_chips).
class _ModePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dipilih;
  final VoidCallback onTap;

  const _ModePill({
    required this.label,
    required this.icon,
    required this.dipilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: dipilih ? AppColors.greenDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dipilih ? AppColors.greenDark : NasabahStyle.line,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: dipilih ? Colors.white : NasabahStyle.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyle.small.copyWith(
                  color: dipilih ? Colors.white : NasabahStyle.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Chip radius atau aksi hapus — pola nasabah_filter_chips.
class _RadiusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool dipilih;
  final VoidCallback onTap;

  const _RadiusChip({
    super.key,
    required this.label,
    required this.dipilih,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: dipilih ? AppColors.greenDark : AppColors.greenLight,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: dipilih ? Colors.white : AppColors.greenDark,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyle.small.copyWith(
                  color: dipilih ? Colors.white : AppColors.greenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}
