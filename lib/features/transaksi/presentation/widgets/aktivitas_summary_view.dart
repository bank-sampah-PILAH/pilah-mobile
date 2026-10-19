import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
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
          // Periode tanpa aktivitas: deretan angka nol hanya menambah bising
          // di atas keadaan kosong.
          if (summary == null || summary.jumlahTransaksi == 0) {
            return const SizedBox.shrink();
          }
          final berat =
              '${summary.totalBerat.toString().replaceFirst(RegExp(r'\.0$'), '').replaceAll('.', ',')} kg';
          final money = summary.saldo < 0
              ? '-${CurrencyFormatter.formatRupiah(summary.saldo.abs())}'
              : CurrencyFormatter.formatRupiah(summary.saldo);
          final values = <(String, String, String?)>[
            ('Total Transaksi', '${summary.jumlahTransaksi}', null),
            (
              'Total Berat Sampah',
              berat,
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
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final cells = [
                for (var i = 0; i < values.length; i++)
                  _SummaryMetric(
                    label: values[i].$1,
                    value: values[i].$2,
                    explanation: values[i].$3,
                    emphasis: i == values.length - 1,
                    valueColor: switch (i) {
                      2 => AppColors.greenDark,
                      3 => AppColors.danger,
                      _ => null,
                    },
                  ),
              ];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: wide
                    ? IntrinsicHeight(
                        child: Row(
                          children: [
                            for (var i = 0; i < cells.length; i++) ...[
                              if (i > 0)
                                const VerticalDivider(
                                    width: 1, color: AppColors.border),
                              Expanded(child: cells[i]),
                            ],
                          ],
                        ),
                      )
                    // Telepon: setoran dan pencairan berdampingan, saldo di
                    // bawahnya selebar penuh, tanpa geser ke samping.
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                    child: _SummaryMetric(
                                  label: 'Total Nilai Setoran',
                                  value: values[2].$2,
                                  valueColor: AppColors.greenDark,
                                )),
                                const VerticalDivider(
                                    width: 1, color: AppColors.border),
                                Expanded(
                                    child: _SummaryMetric(
                                  label: 'Total Pencairan',
                                  value: values[3].$2,
                                  valueColor: AppColors.danger,
                                )),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          cells.last,
                          const Divider(height: 1, color: AppColors.border),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            child: Text(
                              '${summary.jumlahTransaksi} transaksi · $berat',
                              style: AppTextStyle.extraSmall
                                  .copyWith(color: AppColors.grey100),
                            ),
                          ),
                        ],
                      ),
              );
            }),
          );
        },
      );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.explanation,
    this.emphasis = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? explanation;

  /// Saldo periode: angka yang dicari pengurus, jadi paling menonjol.
  final bool emphasis;

  /// Overrides the value colour, such as red for money out.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
          ),
          const SizedBox(height: 2),
          // Angka sangat besar mengecil, bukan terpotong atau keluar kartu.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyle.title1.copyWith(
                color: valueColor ??
                    (emphasis ? AppColors.greenDark : AppColors.black),
              ),
            ),
          ),
        ],
      ),
    );
    return explanation != null
        ? Tooltip(message: explanation!, child: content)
        : content;
  }
}
