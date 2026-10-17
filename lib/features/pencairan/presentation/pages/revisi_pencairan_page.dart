import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/date_time_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_detail_row.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/model/revisi_pencairan.dart';
import '../blocs/revisi_pencairan_cubit.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppBackHeader(title: 'Riwayat Perubahan'),
            Expanded(
              child: BlocBuilder<RevisiPencairanCubit, RevisiPencairanState>(
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
                      return ContentBounds(
                        maxWidth: LayoutBreakpoint.formMaxWidth,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          children: [
                            _VersiCard(
                              judul: 'Versi sekarang',
                              nominal: riwayat.pencairan.nominal,
                              metode: riwayat.pencairan.metode,
                              tanggal: riwayat.pencairan.tanggal,
                              keterangan: riwayat.pencairan.keterangan,
                              saldoSesudah: riwayat.pencairan.saldoSesudah,
                            ),
                            for (final versi in riwayat.revisi)
                              _RevisiCard(versi: versi),
                          ],
                        ),
                      );
                  }
                },
              ),
            ),
          ],
        ),
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
        const Divider(height: 24, color: AppColors.border),
        AppDetailRow(label: 'Alasan perubahan', value: versi.alasan),
        const SizedBox(height: 4),
        Text(
          'Diubah oleh ${versi.diubahOlehNama} · ${_waktu(versi.diubahPada)}',
          style: AppTextStyle.small.copyWith(color: AppColors.grey100),
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
            AppFieldLabel(judul.toUpperCase()),
            const SizedBox(height: 4),
            Text(
              'Rp ${CurrencyFormatter.formatNumber(nominal)}',
              style: AppTextStyle.title1.copyWith(color: AppColors.greenDark),
            ),
            const SizedBox(height: 8),
            AppDetailRow(label: 'Metode', value: metode.label),
            AppDetailRow(label: 'Tanggal', value: _waktu(tanggal)),
            if (keterangan.isNotEmpty)
              AppDetailRow(label: 'Keterangan', value: keterangan),
            AppDetailRow(
              label: 'Saldo sesudah',
              value: 'Rp ${CurrencyFormatter.formatNumber(saldoSesudah)}',
            ),
            ...footer,
          ],
        ),
      ),
    );
  }
}

String _waktu(DateTime? waktu) =>
    waktu == null ? '-' : formatTanggalJamId(waktu);
