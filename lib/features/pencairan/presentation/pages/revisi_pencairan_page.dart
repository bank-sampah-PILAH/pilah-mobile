import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/model/revisi_pencairan.dart';
import '../blocs/revisi_pencairan_cubit.dart';

/// Pengurus-only change history of one pencairan (PIL-230): the current
/// version, then every replaced version with why, who and when.
class RevisiPencairanPage extends StatelessWidget {
  static const route = '/riwayat-perubahan-pencairan';

  final String pencairanId;

  const RevisiPencairanPage({super.key, required this.pencairanId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<RevisiPencairanCubit>(),
      child: RevisiPencairanView(pencairanId: pencairanId),
    );
  }
}

class RevisiPencairanView extends StatefulWidget {
  final String pencairanId;

  const RevisiPencairanView({super.key, required this.pencairanId});

  @override
  State<RevisiPencairanView> createState() => _RevisiPencairanViewState();
}

class _RevisiPencairanViewState extends State<RevisiPencairanView> {
  @override
  void initState() {
    super.initState();
    context.read<RevisiPencairanCubit>().load(widget.pencairanId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Perubahan')),
      body: BlocBuilder<RevisiPencairanCubit, RevisiPencairanState>(
        builder: (context, state) {
          switch (state.status) {
            case RevisiStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case RevisiStatus.failure:
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.errorMessage ?? 'Gagal memuat riwayat'),
                    TextButton(
                      onPressed: () => context
                          .read<RevisiPencairanCubit>()
                          .load(widget.pencairanId),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              );
            case RevisiStatus.loaded:
              final riwayat = state.riwayat!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _VersiCard(
                    judul: 'Versi sekarang',
                    nominal: riwayat.pencairan.nominal,
                    metode: riwayat.pencairan.metode,
                    tanggal: riwayat.pencairan.tanggal,
                    keterangan: riwayat.pencairan.keterangan,
                    saldoSesudah: riwayat.pencairan.saldoSesudah,
                  ),
                  for (final versi in riwayat.revisi) _RevisiCard(versi: versi),
                ],
              );
          }
        },
      ),
    );
  }
}

class _RevisiCard extends StatelessWidget {
  final RevisiPencairan versi;

  const _RevisiCard({required this.versi});

  @override
  Widget build(BuildContext context) {
    return _VersiCard(
      judul: 'Versi ${versi.versi}',
      nominal: versi.nominal,
      metode: versi.metode,
      tanggal: versi.tanggal,
      keterangan: versi.keterangan,
      saldoSesudah: versi.saldoSesudah,
      footer: [
        const SizedBox(height: 8),
        Text('Alasan perubahan', style: AppTextStyle.small),
        Text(versi.alasan, style: AppTextStyle.title1),
        const SizedBox(height: 4),
        Text(
          'Diubah oleh ${versi.diubahOlehNama} · ${_waktu(versi.diubahPada)}',
          style: AppTextStyle.small,
        ),
      ],
    );
  }
}

class _VersiCard extends StatelessWidget {
  final String judul;
  final int nominal;
  final MetodePencairan metode;
  final DateTime? tanggal;
  final String keterangan;
  final int saldoSesudah;
  final List<Widget> footer;

  const _VersiCard({
    required this.judul,
    required this.nominal,
    required this.metode,
    required this.tanggal,
    required this.keterangan,
    required this.saldoSesudah,
    this.footer = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(judul, style: AppTextStyle.small),
            const SizedBox(height: 4),
            Text('Rp ${formatRupiahId(nominal)}', style: AppTextStyle.title1),
            Text(
              '${metode.label} · ${_waktu(tanggal)}',
              style: AppTextStyle.small,
            ),
            if (keterangan.isNotEmpty)
              Text(keterangan, style: AppTextStyle.small),
            Text(
              'Saldo sesudah Rp ${formatRupiahId(saldoSesudah)}',
              style: AppTextStyle.small,
            ),
            ...footer,
          ],
        ),
      ),
    );
  }
}

String _waktu(DateTime? waktu) {
  if (waktu == null) return '-';
  final h = waktu.hour.toString().padLeft(2, '0');
  final m = waktu.minute.toString().padLeft(2, '0');
  return '${formatTanggalId(waktu)}, $h:$m';
}
