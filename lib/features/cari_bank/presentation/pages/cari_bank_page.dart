import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_cubit.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_state.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/widgets/peta_bank_view.dart';
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
          onTap: () => context.push(
            BankSampahDetailPage.route,
            extra: bank.id,
          ),
        ),
      ),
    );
  }
}
