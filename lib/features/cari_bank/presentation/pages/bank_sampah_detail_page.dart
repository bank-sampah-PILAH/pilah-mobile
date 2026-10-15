import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/cari_bank/data/datasources/cari_bank_remote_data_source.dart';
import 'package:pilah_mobile/features/cari_bank/domain/entities/cari_bank_entities.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/bank_lokasi_map_page.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/pages/perbandingan_harga_page.dart';
import 'package:pilah_mobile/services/di.dart';

/// Detail layanan satu bank sampah (PIL-308): profil, status, koordinat, dan
/// daftar layanan (jenis sampah + harga master).
class BankSampahDetailPage extends StatefulWidget {
  static const route = '/cari-bank-sampah/detail';

  final String bankSampahId;

  const BankSampahDetailPage({super.key, required this.bankSampahId});

  @override
  State<BankSampahDetailPage> createState() => _BankSampahDetailPageState();
}

enum _Muat { loading, gagal, selesai }

class _BankSampahDetailPageState extends State<BankSampahDetailPage> {
  _Muat _state = _Muat.loading;
  BankSampahDetailEntity? _detail;
  String? _pesan;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _state = _Muat.loading;
      _pesan = null;
    });
    final either = await apiCall<BankSampahDetailEntity>(
      func: di<CariBankRemoteDataSource>().detail(widget.bankSampahId),
      mapper: (value) => value as BankSampahDetailEntity,
    );
    if (!mounted) return;
    either.fold(
      (error) => setState(() {
        _state = _Muat.gagal;
        _pesan = error.displayMessage;
      }),
      (detail) => setState(() {
        _state = _Muat.selesai;
        _detail = detail;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(detail?.nama ?? 'Bank Sampah',
            style: AppTextStyle.small.copyWith(
              fontWeight: FontWeight.w600,
              color: NasabahStyle.ink,
            )),
        centerTitle: true,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    switch (_state) {
      case _Muat.loading:
        return const Center(child: CircularProgressIndicator());
      case _Muat.gagal:
        return Column(
          children: [
            const Spacer(),
            SizedBox(
              height: 280,
              child: EmptyView(
                title: 'Detail Bank Sampah Belum Ditemukan',
                subtitle: _pesan,
                icon: Icons.error_outline,
              ),
            ),
            TextButton.icon(
              key: const Key('detail_bank_coba_lagi'),
              onPressed: _muat,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
            ),
            const Spacer(),
          ],
        );
      case _Muat.selesai:
        return _IsiDetail(detail: _detail!);
    }
  }
}

class _IsiDetail extends StatelessWidget {
  final BankSampahDetailEntity detail;

  const _IsiDetail({required this.detail});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(detail: detail),
        const SizedBox(height: 8),
        _row('Kota', detail.kota),
        _row('Alamat', detail.alamat),
        if (detail.lokasi != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: OutlinedButton.icon(
              key: const Key('detail_bank_buka_peta'),
              onPressed: () => Navigator.of(context, rootNavigator: true)
                  .push(MaterialPageRoute(
                builder: (_) => BankLokasiMapPage(
                  nama: detail.nama,
                  latitude: detail.lokasi!.latitude,
                  longitude: detail.lokasi!.longitude,
                ),
              )),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.greenDark,
                side: const BorderSide(color: AppColors.greenDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(
                'Lihat Lokasi di Peta',
                style: AppTextStyle.small.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Layanan',
          style: NasabahStyle.text(15, weight: FontWeight.w600),
        ),
        if (detail.layanan.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada jenis sampah aktif pada bank ini.',
              style: NasabahStyle.text(14, color: NasabahStyle.muted),
            ),
          )
        else
          ...detail.layanan.map(_LayananBaris.new),
        if (detail.layanan.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CustomPrimaryButton(
              key: const Key('detail_bank_bandingkan_harga'),
              title: 'Bandingkan Harga',
              onPressed: () {
                final layanan = detail.layanan.first;
                // Route through the router (registered for this page); the
                // seed record carries the jenis + asal-bank fields.
                context.push(
                  PerbandinganHargaPage.route,
                  extra: PerbandinganSeed(
                    jenisSampahId: layanan.id,
                    bankAsalId: detail.id,
                    bankAsalNama: detail.nama,
                    layananAsal: detail.layanan,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: NasabahStyle.text(13, color: NasabahStyle.muted),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: NasabahStyle.text(14),
              ),
            ),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  final BankSampahDetailEntity detail;

  const _Header({required this.detail});

  String get _initials => detail.nama
      .split(RegExp(r'\s+'))
      .where((kata) => kata.isNotEmpty)
      .take(2)
      .map((kata) => kata[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(18),
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.nama,
                style: AppTextStyle.title1.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: CustomStatusBadge(isActive: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LayananBaris extends StatelessWidget {
  final LayananEntity layanan;

  const _LayananBaris(this.layanan);

  @override
  Widget build(BuildContext context) {
    final harga = double.tryParse(layanan.hargaPerKg) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${layanan.kode} · ${layanan.namaSampah}',
                  style: NasabahStyle.text(14, weight: FontWeight.w500),
                ),
                if (layanan.deskripsi.isNotEmpty)
                  Text(
                    layanan.deskripsi,
                    style:
                        NasabahStyle.text(12, color: NasabahStyle.labelMuted),
                  ),
              ],
            ),
          ),
          Text(
            '${CurrencyFormatter.formatRupiah(harga.round())}/kg',
            style: AppTextStyle.small,
          ),
        ],
      ),
    );
  }
}
