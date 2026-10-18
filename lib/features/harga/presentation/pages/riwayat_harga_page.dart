import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/date_time_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/versi_harga.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/riwayat_harga_cubit.dart';
import 'package:pilah_mobile/services/di.dart';

/// Every price version of one jenis sampah, newest first (PIL-331).
class RiwayatHargaPage extends StatelessWidget {
  static const route = '/riwayat-harga';

  final HargaEntity jenis;

  const RiwayatHargaPage({super.key, required this.jenis});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<RiwayatHargaCubit>(),
      child: RiwayatHargaView(jenisId: jenis.id, namaJenis: jenis.name),
    );
  }
}

class RiwayatHargaView extends StatefulWidget {
  final String jenisId;
  final String namaJenis;

  const RiwayatHargaView({
    super.key,
    required this.jenisId,
    required this.namaJenis,
  });

  @override
  State<RiwayatHargaView> createState() => _RiwayatHargaViewState();
}

class _RiwayatHargaViewState extends State<RiwayatHargaView> {
  @override
  void initState() {
    super.initState();
    context.read<RiwayatHargaCubit>().load(widget.jenisId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat Harga'),
            Text(widget.namaJenis, style: AppTextStyle.small),
          ],
        ),
      ),
      body: BlocBuilder<RiwayatHargaCubit, RiwayatHargaState>(
        builder: (context, state) {
          switch (state.status) {
            case RiwayatHargaStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case RiwayatHargaStatus.failure:
              return Column(
                children: [
                  Expanded(
                    child: EmptyView(
                      title: 'Gagal Memuat Riwayat Harga',
                      subtitle: state.errorMessage,
                      icon: Icons.error_outline,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: TextButton(
                      onPressed: () => context
                          .read<RiwayatHargaCubit>()
                          .load(widget.jenisId),
                      child: const Text('Coba lagi'),
                    ),
                  ),
                ],
              );
            case RiwayatHargaStatus.loaded:
              if (state.riwayat.isEmpty) {
                return const EmptyView(
                  title: 'Belum Ada Riwayat Harga',
                  subtitle:
                      'Harga yang diatur untuk jenis ini akan tampil di sini.',
                  icon: Icons.history,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.riwayat.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) =>
                    _VersiHargaCard(versi: state.riwayat[index]),
              );
          }
        },
      ),
    );
  }
}

class _VersiHargaCard extends StatelessWidget {
  final VersiHarga versi;

  const _VersiHargaCard({required this.versi});

  @override
  Widget build(BuildContext context) {
    final (label, latar, warna) = _gayaStatus(versi.status);
    final oleh = versi.dibuatOleh;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${CurrencyFormatter.formatRupiahSen(versi.hargaSen)} / ${versi.satuan}',
                  style: AppTextStyle.title1.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    decoration: versi.status == StatusVersiHarga.digantikan
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              CustomStatusBadge(
                statusText: label,
                backgroundColor: latar,
                textColor: warna,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mulai ${formatTanggalJamId(versi.berlakuMulai.toLocal())}',
            style: AppTextStyle.small.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 2),
          Text(
            oleh == null ? 'Harga awal dari data lama' : 'Dicatat oleh $oleh',
            style: AppTextStyle.extraSmall.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

(String, Color, Color) _gayaStatus(StatusVersiHarga status) {
  switch (status) {
    case StatusVersiHarga.terjadwal:
      return ('Terjadwal', AppColors.avatarYellow, AppColors.avatarYellowText);
    case StatusVersiHarga.berlaku:
      return ('Berlaku sekarang', AppColors.greenLight, AppColors.greenDark);
    case StatusVersiHarga.sebelumnya:
      return ('Sebelumnya', Colors.grey.shade100, Colors.grey.shade600);
    case StatusVersiHarga.digantikan:
      return ('Digantikan', Colors.grey.shade100, Colors.grey.shade500);
  }
}
