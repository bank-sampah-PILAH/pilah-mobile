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

  static const _horizontalPadding = 12.0;
  static const _columnSpacing = 16.0;

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
          final values = <(String, String, String?)>[
            ('Total Transaksi', '${summary.jumlahTransaksi}', null),
            (
              'Total Berat Sampah',
              '${summary.totalBerat.toString().replaceFirst(RegExp(r'\.0$'), '').replaceAll('.', ',')} kg',
              null,
            ),
            (
              'Total Nilai Setoran',
              CurrencyFormatter.formatRupiah(summary.totalSetoran),
              null,
            ),
            (
              'Total Pencairan',
              CurrencyFormatter.formatRupiah(summary.totalPencairan),
              null,
            ),
            (
              'Saldo Periode',
              money,
              'Selisih total setoran dan pencairan pada periode dan filter yang dipilih.'
            ),
          ];
          return LayoutBuilder(builder: (context, constraints) {
            final inline = constraints.maxWidth < 720;
            final columns = inline ? 1 : 5;
            final width = (constraints.maxWidth -
                    2 * _horizontalPadding -
                    (columns - 1) * _columnSpacing) /
                columns;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: _horizontalPadding, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Wrap(
                  spacing: _columnSpacing,
                  runSpacing: 4,
                  children: values
                      .map((metric) => _SummaryMetric(
                          label: metric.$1,
                          value: metric.$2,
                          explanation: metric.$3,
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
      required this.inline,
      this.explanation});

  final String label;
  final String value;
  final double width;
  final bool inline;
  final String? explanation;

  @override
  Widget build(BuildContext context) {
    final texts = [
      Text(label, style: AppTextStyle.small),
      Text(value,
          style: AppTextStyle.headline3.copyWith(fontWeight: FontWeight.bold)),
    ];
    final content = _layout(texts);
    return SizedBox(
      width: width,
      child: explanation != null
          ? Tooltip(message: explanation!, child: content)
          : content,
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
