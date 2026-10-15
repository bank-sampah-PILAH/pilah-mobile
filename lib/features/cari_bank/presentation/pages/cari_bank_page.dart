import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/core/utils/formatter/jarak_formatter.dart';
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
          appBar: AppBar(
            title: const Text('Cari Bank Sampah'),
            centerTitle: true,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const Key('cari_bank_kota'),
                  onChanged: context.read<CariBankCubit>().ketikKota,
                  decoration: const InputDecoration(
                    hintText:
                        'Filter kota (mis. Depok, Kota Depok, Kab. Depok)',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<String>(
                  key: const Key('cari_bank_mode'),
                  segments: const [
                    ButtonSegment(value: 'Daftar', label: Text('Daftar')),
                    ButtonSegment(value: 'Peta', label: Text('Peta')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) =>
                      setState(() => _mode = selection.first),
                ),
              ),
              // Mode lokasi (PIL-314): dua pintu masuk — titik sekarang atau
              // titik pilihan peta — lalu cip radius hanya saat aktif.
              if (state is CariBankLoaded && state.dalamRadiusKm == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('cari_bank_dekat_saya'),
                          onPressed: () =>
                              context.read<CariBankCubit>().pilihLokasiSaya(),
                          icon: const Icon(Icons.near_me_outlined, size: 18),
                          label: const Text('Di dekat saya'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('cari_bank_pilih_di_peta'),
                          onPressed: () async {
                            // Same Navigator pattern as profile's map picker —
                            // MapPickerPage is not go_router-registered.
                            final titik = await Navigator.of(context)
                                .push<({double latitude, double longitude})>(
                              MaterialPageRoute(
                                // Thread the test seam (PIL-330) when set so no
                                // real OSM tile is fetched inside tests; null
                                // lets MapPickerPage default to the real layer.
                                builder: (_) => widget.tileLayerBuilder == null
                                    ? const MapPickerPage()
                                    : MapPickerPage(
                                        tileLayerBuilder:
                                            widget.tileLayerBuilder!,
                                      ),
                              ),
                            );
                            if (titik != null && context.mounted) {
                              context
                                  .read<CariBankCubit>()
                                  .pilihDariPeta(titik);
                            }
                          },
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Di peta'),
                        ),
                      ),
                    ],
                  ),
                )
              else if (state is CariBankLoaded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final km in const [1.0, 5.0, 10.0, 25.0])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: OutlinedButton(
                              key: Key('cari_bank_radius_${km.toInt()}'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: km == state.dalamRadiusKm
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : null,
                              ),
                              onPressed: () => context
                                  .read<CariBankCubit>()
                                  .pilihRadiusKm(km),
                              child: Text('${km.toInt()} km'),
                            ),
                          ),
                        ActionChip(
                          key: const Key('cari_bank_hapus_lokasi'),
                          avatar: const Icon(Icons.close, size: 16),
                          label: const Text('Hapus lokasi'),
                          onPressed: () =>
                              context.read<CariBankCubit>().hapusLokasi(),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(child: _body(context, state)),
            ],
          ),
        ),
      );

  Widget _body(BuildContext context, CariBankState state) {
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
    if (_mode == 'Peta' &&
        // Peta mode shows only banks a marker can stand on; banks without
        // coordinates stay list-only (PIL-330).
        !loaded.items.any((bank) => bank.lokasi != null)) {
      return const EmptyView(
        title: 'Tidak Ada Bank Dengan Lokasi',
        subtitle: 'Bank yang dipilih tidak memasang koordinat di peta.',
        icon: Icons.map_outlined,
      );
    }
    if (_mode == 'Peta') {
      return PetaBankView(
        banks: loaded.items,
        tileLayerBuilder: widget.tileLayerBuilder,
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
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: loaded.items.length + (loaded.hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
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

class _BankTile extends StatelessWidget {
  final BankSampahDirectoryEntity bank;

  const _BankTile({required this.bank});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        key: Key('cari_bank_row_${bank.id}'),
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
          title: Text(
            bank.nama,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${bank.kota} · ${bank.alamat}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: bank.jarakKm == null
              ? null
              : PillTag(text: formatJarakId(double.parse(bank.jarakKm!))),
          onTap: () => context.push(
            BankSampahDetailPage.route,
            extra: bank.id,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
}
