import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/features/cari_bank/data/datasources/cari_bank_remote_data_source.dart';
import 'package:pilah_mobile/features/cari_bank/domain/entities/cari_bank_entities.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
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
      appBar: AppBar(
        title: Text(detail?.nama ?? 'Bank Sampah',
            style: AppTextStyle.small.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
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
        _row('Lokasi di peta', tampilkanLokasi(detail)),
        const SizedBox(height: 12),
        Text(
          'Layanan',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        if (detail.layanan.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada jenis sampah aktif pada bank ini.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...detail.layanan.map(_LayananBaris.new),
      ],
    );
  }

  static const _labelStyle = TextStyle(color: Colors.grey, fontSize: 13);
  static const _valueStyle = TextStyle(fontSize: 14);

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: _labelStyle),
            ),
            Expanded(
              child: Text(value.isEmpty ? '—' : value, style: _valueStyle),
            ),
          ],
        ),
      );
}

/// Coordinates as a readable text pair; the full map view on search arrives
/// with PIL-330.
String tampilkanLokasi(BankSampahDetailEntity detail) {
  final lokasi = detail.lokasi;
  if (lokasi == null) return 'Belum dipasang';
  return '${lokasi.latitude.toStringAsFixed(6)}, '
      '${lokasi.longitude.toStringAsFixed(6)}';
}

class _Header extends StatelessWidget {
  final BankSampahDetailEntity detail;

  const _Header({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          child: Icon(Icons.storefront_outlined, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.nama,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
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
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (layanan.deskripsi.isNotEmpty)
                  Text(
                    layanan.deskripsi,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          ),
          Text(
            'Rp ${formatRupiahId(harga.round())}/kg',
            style: AppTextStyle.small,
          ),
        ],
      ),
    );
  }
}
