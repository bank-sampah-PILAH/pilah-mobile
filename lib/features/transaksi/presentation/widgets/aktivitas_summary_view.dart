import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import '../cubit/riwayat_aktivitas_cubit.dart';
import '../cubit/riwayat_aktivitas_state.dart';

/// Displays authoritative totals for the selected period and filters.
class AktivitasSummaryView extends StatelessWidget {
  const AktivitasSummaryView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RiwayatAktivitasCubit, RiwayatAktivitasState>(
        builder: (context, state) {
          if (state.status == AktivitasStatus.initial ||
              state.status == AktivitasStatus.loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(
                  semanticsLabel: 'Memuat ringkasan laporan'),
            );
          }
          if (state.status == AktivitasStatus.failure) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Ringkasan gagal dimuat. Silakan coba lagi.'),
            );
          }
          final summary = state.summary;
          if (summary == null) return const SizedBox.shrink();
          final money = summary.saldo < 0
              ? '-${CurrencyFormatter.formatRupiah(summary.saldo.abs())}'
              : CurrencyFormatter.formatRupiah(summary.saldo);
          final values = <(String, String)>[
            ('Total Transaksi', '${summary.jumlahTransaksi}'),
            (
              'Total Berat Sampah',
              '${summary.totalBerat.toString().replaceFirst(RegExp(r'\.0$'), '').replaceAll('.', ',')} kg'
            ),
            (
              'Total Nilai Setoran',
              CurrencyFormatter.formatRupiah(summary.totalSetoran)
            ),
            (
              'Total Pencairan',
              CurrencyFormatter.formatRupiah(summary.totalPencairan)
            ),
            ('Saldo Periode', money),
          ];
          return LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 5 : 2;
            final inline = columns != 5;
            final width = inline
                ? constraints.maxWidth - 24
                : (constraints.maxWidth - 24 - 64) / columns;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: values
                      .map((metric) => _SummaryMetric(
                          label: metric.$1,
                          value: metric.$2,
                          width: width,
                          inline: inline))
                      .toList(),
                ),
              ),
            );
          });
        },
      );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric(
      {required this.label,
      required this.value,
      required this.width,
      required this.inline});

  final String label;
  final String value;
  final double width;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final texts = [
      Text(label, style: AppTextStyle.small),
      Text(value,
          style: AppTextStyle.headline3.copyWith(fontWeight: FontWeight.bold)),
    ];
    return SizedBox(
      width: width,
      child: label == 'Saldo Periode'
          ? Tooltip(
              message:
                  'Selisih total setoran dan pencairan pada periode dan filter yang dipilih.',
              child: _layout(texts),
            )
          : _layout(texts),
    );
  }

  Widget _layout(List<Widget> texts) => inline
      ? Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 2,
          children: texts,
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [texts.first, const SizedBox(height: 2), texts.last],
        );
}
