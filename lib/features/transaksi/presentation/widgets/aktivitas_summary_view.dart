import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import '../../domain/entities/aktivitas_summary.dart';
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
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _SummaryCard(summary: summary),
          );
        },
      );
}

/// Ringkasan periode dalam satu baris, untuk di dalam kartu tabel di layar
/// lebar. Angkanya sama dengan [AktivitasSummaryView]; hanya bentuknya yang
/// ringkas, supaya header halaman tetap sedikit memakan tinggi.
class AktivitasSummaryStrip extends StatelessWidget {
  const AktivitasSummaryStrip({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RiwayatAktivitasCubit, RiwayatAktivitasState>(
        builder: (context, state) {
          final summary = state.summary;
          if (state.status != AktivitasStatus.loaded ||
              summary == null ||
              summary.jumlahTransaksi == 0) {
            return const SizedBox.shrink();
          }
          return _SummaryStripRow(summary: summary);
        },
      );
}

class _SummaryStripRow extends StatelessWidget {
  const _SummaryStripRow({required this.summary});

  final AktivitasSummary summary;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, String value,
            {Color? color, bool bold = false}) =>
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '$label  ',
              style: AppTextStyle.small.copyWith(color: AppColors.grey100),
            ),
            TextSpan(
              text: value,
              style: AppTextStyle.small.copyWith(
                color: color ?? AppColors.black,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.xs,
        children: [
          item('Transaksi', '${summary.jumlahTransaksi}'),
          item('Berat', _beratLabel(summary)),
          item('Setoran', CurrencyFormatter.formatRupiah(summary.totalSetoran),
              color: AppColors.greenDark),
          item('Pencairan',
              CurrencyFormatter.formatRupiah(summary.totalPencairan),
              color: AppColors.danger),
          Tooltip(
            message:
                'Selisih total setoran dan pencairan pada periode dan filter yang dipilih.',
            child: item('Saldo', _saldoLabel(summary),
                color: AppColors.greenDark, bold: true),
          ),
        ],
      ),
    );
  }
}

String _beratLabel(AktivitasSummary summary) =>
    '${summary.totalBerat.toString().replaceFirst(RegExp(r'\.0$'), '').replaceAll('.', ',')} kg';

String _saldoLabel(AktivitasSummary summary) => summary.saldo < 0
    ? '-${CurrencyFormatter.formatRupiah(summary.saldo.abs())}'
    : CurrencyFormatter.formatRupiah(summary.saldo);

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final AktivitasSummary summary;

  String get _berat => _beratLabel(summary);

  String get _saldo => _saldoLabel(summary);

  _SummaryMetric get _setoran => _SummaryMetric(
        label: 'Total Nilai Setoran',
        value: CurrencyFormatter.formatRupiah(summary.totalSetoran),
        valueColor: AppColors.greenDark,
      );

  _SummaryMetric get _pencairan => _SummaryMetric(
        label: 'Total Pencairan',
        value: CurrencyFormatter.formatRupiah(summary.totalPencairan),
        valueColor: AppColors.danger,
      );

  _SummaryMetric get _saldoMetric => _SummaryMetric(
        label: 'Saldo Periode',
        value: _saldo,
        explanation:
            'Selisih total setoran dan pencairan pada periode dan filter yang dipilih.',
        emphasis: true,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= 720 ? _wide() : _phone(),
      ),
    );
  }

  Widget _wide() {
    final cells = [
      _SummaryMetric(
          label: 'Total Transaksi', value: '${summary.jumlahTransaksi}'),
      _SummaryMetric(label: 'Total Berat Sampah', value: _berat),
      _setoran,
      _pencairan,
      _saldoMetric,
    ];
    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(child: cells[i]),
          ],
        ],
      ),
    );
  }

  // Telepon: setoran dan pencairan berdampingan, saldo di bawahnya selebar
  // penuh, tanpa geser ke samping.
  Widget _phone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _setoran),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(child: _pencairan),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        _saldoMetric,
        const Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            '${summary.jumlahTransaksi} transaksi · $_berat',
            style: AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
          ),
        ),
      ],
    );
  }
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
