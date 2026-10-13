import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/features/cari_bank/domain/entities/cari_bank_entities.dart';
import 'package:pilah_mobile/features/perbandingan_harga/domain/entities/perbandingan_harga_entities.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_cubit.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_state.dart';
import 'package:pilah_mobile/services/di.dart';

/// Seed yang dibawa halaman detail saat masuk ke perbandingan: jenis awal
/// (kode pertama layanan) dan bank acuannya.
class PerbandinganSeed {
  final String jenisSampahId;
  final String bankAsalId;
  final String bankAsalNama;
  final List<LayananEntity> layananAsal;

  const PerbandinganSeed({
    required this.jenisSampahId,
    required this.bankAsalId,
    required this.bankAsalNama,
    required this.layananAsal,
  });
}

/// Perbandingan harga satu jenis sampah antar bank (PIL-309), diambil dari
/// layanan (kode) sebuah bank acuan — kode yang sama mencari baris yang
/// sejenis di bank lain.
class PerbandinganHargaPage extends StatefulWidget {
  static const route = '/perbandingan-harga';

  final String jenisSampahId;

  /// Bank yang jadi acuan (pre-check): id, nama, dan layanannya untuk
  /// dropdown jenis.
  final String bankAsalId;
  final String bankAsalNama;
  final List<LayananEntity> layananAsal;

  const PerbandinganHargaPage({
    super.key,
    required this.jenisSampahId,
    required this.bankAsalId,
    required this.bankAsalNama,
    required this.layananAsal,
  });

  @override
  State<PerbandinganHargaPage> createState() => _PerbandinganHargaPageState();
}

class _PerbandinganHargaPageState extends State<PerbandinganHargaPage> {
  late final PerbandinganHargaCubit _cubit = di<PerbandinganHargaCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.muat(
      jenisSampahId: widget.jenisSampahId,
      bankIds: [widget.bankAsalId],
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _cubit,
        child: BlocBuilder<PerbandinganHargaCubit, PerbandinganHargaState>(
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              title: const Text('Bandingkan Harga'),
              centerTitle: true,
            ),
            body: _body(state),
          ),
        ),
      );

  Widget _body(PerbandinganHargaState state) {
    if (state is PerbandinganHargaError) {
      return Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 280,
            child: EmptyView(
              title: 'Gagal Memuat Perbandingan',
              subtitle: state.message,
              icon: Icons.wifi_off_outlined,
            ),
          ),
          const Spacer(),
        ],
      );
    }
    if (state is PerbandinganHargaLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final loaded = state as PerbandinganHargaLoaded;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Jenis: ${loaded.data.jenisSampah.namaSampah} '
          '(${loaded.data.jenisSampah.nomor})',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 12),
        ...loaded.data.perbandingan.map(_barisBank),
      ],
    );
  }

  Widget _barisBank(PerbandinganBankHargaEntity row) {
    // The backend sends a decimal string ("3000.00"); rupiah display keeps
    // the whole part (no sen — kaidah rupiah bulat).
    final rupiah = double.tryParse(row.hargaPerKg ?? '')?.floor();
    final hargaTampil = row.hargaTidakTersedia || rupiah == null
        ? 'Harga belum tersedia'
        : 'Rp ${formatRupiahId(rupiah)}';
    final nama = row.nama ?? '(bank tidak bisa dibandingkan)';
    return Card(
      key: Key('perbandingan_baris_${row.bankSampahId}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(nama, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(row.kota ?? ''),
        trailing: Text(
          hargaTampil,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: row.hargaTidakTersedia ? Colors.grey : Colors.green.shade700,
          ),
        ),
      ),
    );
  }
}
