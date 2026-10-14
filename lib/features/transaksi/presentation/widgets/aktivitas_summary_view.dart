import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
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
            ('Jumlah transaksi', '${summary.jumlahTransaksi}'),
            (
              'Total berat',
              '${summary.totalBerat.toString().replaceFirst(RegExp(r'\.0$'), '').replaceAll('.', ',')} kg'
            ),
            (
              'Nilai setoran',
              CurrencyFormatter.formatRupiah(summary.totalSetoran)
            ),
            (
              'Total pencairan',
              CurrencyFormatter.formatRupiah(summary.totalPencairan)
            ),
            ('Saldo periode', money),
          ];
          return LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 5 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values
                    .map((metric) => _SummaryMetric(
                        label: metric.$1, value: metric.$2, width: width))
                    .toList(),
              ),
            );
          });
        },
      );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric(
      {required this.label, required this.value, required this.width});

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
