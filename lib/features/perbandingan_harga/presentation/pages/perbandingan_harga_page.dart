import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/cari_bank/data/datasources/cari_bank_remote_data_source.dart';
import 'package:pilah_mobile/features/cari_bank/domain/entities/cari_bank_entities.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
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

/// Jumlah bank maksimal pada satu perbandingan — sama dengan batas endpoint.
const int _bankMaksimal = 10;

String _formatTanggal(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

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
  late final List<String> _bankIds = [widget.bankAsalId];
  late String _jenisSampahId = widget.jenisSampahId;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() => _cubit.muat(
        jenisSampahId: _jenisSampahId,
        bankIds: _bankIds,
      );

  Future<void> _pilihJenis(String? layananId) async {
    if (layananId == null || layananId == _jenisSampahId) return;
    setState(() => _jenisSampahId = layananId);
    _muat();
  }

  Future<void> _tambahBank() async {
    if (_bankIds.length >= _bankMaksimal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Maksimal $_bankMaksimal bank dalam satu perbandingan.'),
        ),
      );
      return;
    }
    final terpilih = await showModalBottomSheet<BankSampahDirectoryEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PilihBankSheet(
        bankTerpilih: _bankIds.toSet(),
      ),
    );
    if (terpilih == null || !mounted) return;
    setState(() => _bankIds.add(terpilih.id));
    _muat();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _cubit,
        child: BlocBuilder<PerbandinganHargaCubit, PerbandinganHargaState>(
          builder: (context, state) => Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                'Bandingkan Harga',
                style: AppTextStyle.appBar.copyWith(color: NasabahStyle.ink),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              scrolledUnderElevation: 0,
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
        DropdownButtonFormField<String>(
          initialValue: _jenisSampahId,
          isExpanded: true,
          style: NasabahStyle.text(14),
          dropdownColor: Colors.white,
          decoration: NasabahStyle.input(hint: 'Jenis sampah')
              .copyWith(labelText: 'Jenis sampah'),
          items: widget.layananAsal
              .map(
                (layanan) => DropdownMenuItem(
                  value: layanan.id,
                  child: Text('${layanan.kode} · ${layanan.namaSampah}'),
                ),
              )
              .toList(),
          onChanged: _pilihJenis,
        ),
        const SizedBox(height: 8),
        // Satuan comes from the backend envelope of the loaded comparison.
        Text(
          'Satuan: ${loaded.data.jenisSampah.satuan}',
          style: NasabahStyle.text(13, color: NasabahStyle.muted),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('perbandingan_tambah_bank'),
          onPressed: _tambahBank,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.greenDark,
            side: const BorderSide(color: AppColors.greenDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          icon: const Icon(Icons.add_business_outlined, size: 18),
          label: Text(
            'Tambah bank pembanding',
            style: AppTextStyle.small.copyWith(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        : CurrencyFormatter.formatRupiah(rupiah);
    final nama = row.nama ?? '(bank tidak bisa dibandingkan)';
    final berlaku = row.berlakuMulai == null
        ? null
        : 'Berlaku ${_formatTanggal(DateTime.parse(row.berlakuMulai!).toLocal())}';
    final tersedia = !row.hargaTidakTersedia && rupiah != null;
    return Container(
      key: Key('perbandingan_baris_${row.bankSampahId}'),
      margin: const EdgeInsets.only(bottom: 12),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tersedia ? AppColors.greenLight : Colors.grey[200],
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.storefront_outlined,
              size: 22,
              color: tersedia ? AppColors.greenDark : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: AppTextStyle.title1.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (row.kota != null && row.kota!.isNotEmpty) row.kota!,
                    if (berlaku != null) berlaku,
                  ].join(' · '),
                  style: AppTextStyle.small.copyWith(
                    color: Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hargaTampil,
            style: AppTextStyle.title1.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: tersedia ? AppColors.greenDark : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet pemilih bank pembanding: satu halaman direktori (joinable-filtered
/// di backend), pencarian klien, bank yang sudah dibandingkan disembunyikan.
class _PilihBankSheet extends StatefulWidget {
  final Set<String> bankTerpilih;

  const _PilihBankSheet({required this.bankTerpilih});

  @override
  State<_PilihBankSheet> createState() => _PilihBankSheetState();
}

class _PilihBankSheetState extends State<_PilihBankSheet> {
  List<BankSampahDirectoryEntity> _semua = [];
  String _query = '';
  _MuatSheet _state = _MuatSheet.loading;
  String? _pesan;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() => _state = _MuatSheet.loading);
    try {
      final page =
          await di<CariBankRemoteDataSource>().search(page: 1, q: _query);
      if (!mounted) return;
      setState(() {
        _semua = page.items
            .where((b) => !widget.bankTerpilih.contains(b.id))
            .toList();
        _state = _semua.isEmpty ? _MuatSheet.kosong : _MuatSheet.selesai;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _MuatSheet.gagal;
        _pesan = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        // Sheet mengambang dengan radius atas — pola sheet pemilih lainnya.
        margin: const EdgeInsets.only(top: 48),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 480,
            child: Column(
              children: [
                const BottomSheetHeader(title: 'Pilih Bank Pembanding'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: CustomSearchField(
                    key: const Key('perbandingan_picker_cari'),
                    hintText: 'Cari bank sampah',
                    onChanged: (v) {
                      _query = v;
                      _muat();
                    },
                  ),
                ),
                Expanded(child: _isi()),
              ],
            ),
          ),
        ),
      );

  Widget _isi() => switch (_state) {
        _MuatSheet.loading => const Center(child: CircularProgressIndicator()),
        _MuatSheet.gagal => Center(
            child: EmptyView(
              title: 'Gagal Memuat Daftar Bank',
              subtitle: _pesan,
              icon: Icons.wifi_off_outlined,
            ),
          ),
        _MuatSheet.kosong => const Center(
            child: EmptyView(
              title: 'Tidak Ada Bank Sampah Lain',
              subtitle: 'Semua bank sudah masuk perbandingan.',
              icon: Icons.search_off,
            ),
          ),
        _MuatSheet.selesai => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            shrinkWrap: true,
            itemCount: _semua.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final bank = _semua[i];
              return _PilihanBank(bank: bank);
            },
          ),
      };
}

/// Baris pilihan bank — pola kartu daftar nasabah (avatar inisial + nama
/// tegas + kota), ketuk untuk memilih.
class _PilihanBank extends StatelessWidget {
  final BankSampahDirectoryEntity bank;

  const _PilihanBank({required this.bank});

  String get _initials => bank.nama
      .split(RegExp(r'\s+'))
      .where((kata) => kata.isNotEmpty)
      .take(2)
      .map((kata) => kata[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: Key('perbandingan_picker_bank_${bank.id}'),
        onTap: () => Navigator.pop(context, bank),
        child: Container(
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(14),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.nama,
                      style: AppTextStyle.title1.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bank.kota,
                      style: AppTextStyle.small.copyWith(
                        color: Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.greenDark,
              ),
            ],
          ),
        ),
      );
}

enum _MuatSheet { loading, gagal, kosong, selesai }
