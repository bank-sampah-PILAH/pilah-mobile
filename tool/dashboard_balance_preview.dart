// Demo-only component preview. No authentication, network, or real customer data.
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:pilah_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:pilah_mobile/features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_web_kpi_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/total_kas_card.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_widgets.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';

// Preview-only scenarios; these never supply cash to the production dashboard.
class _CashScenarioPreview extends StatelessWidget {
  final int cash;
  const _CashScenarioPreview(this.cash);

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (_, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : 1;
        final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
        final cards = [
          const DashboardKpiCard(
            label: 'Saldo Tabungan Nasabah',
            value: 'Rp 9.876.543',
            icon: Icons.savings_outlined,
          ),
          DashboardKpiCard(
            label: 'Kas Operasional',
            value: CurrencyFormatter.formatRupiah(cash),
            icon: Icons.account_balance_wallet_outlined,
          ),
          const DashboardKpiCard(
            label: 'Nilai Setoran Bulan Ini',
            value: 'Rp 1.234.567',
            icon: Icons.receipt_long_outlined,
          ),
        ];
        return Wrap(spacing: 16, runSpacing: 16, children: [
          for (final card in cards) SizedBox(width: width, child: card),
        ]);
      });
}

class _DemoRepository implements DashboardRepository {
  @override
  Future<Either<NetworkException, DashboardStats>> getStats() async =>
      const Right(DashboardStats(
        totalSaldoNasabah: 9876543,
        totalKasBulanIni: 1234567,
        nasabahAktif: 12,
        totalSampahKg: 123.5,
        transaksiBulanIni: 9,
      ));
}

void main() {
  final scenario = Uri.base.queryParameters['cash'];
  final cash = scenario == 'positive'
      ? 2500000
      : scenario == 'zero'
          ? 0
          : null;
  runApp(BlocProvider(
    create: (_) => DashboardCubit(GetDashboardStatsUseCase(_DemoRepository()))
      ..loadStats(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(
            title: Text(cash == null
                ? 'Dashboard Pengurus · Data demo'
                : 'Simulasi Kas Operasional · Data demo')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (_, constraints) => cash != null
                ? _CashScenarioPreview(cash)
                : constraints.maxWidth < 600
                    ? const TotalKasCard()
                    : const DashboardWebKpiSection(),
          ),
        ),
      ),
    ),
  ));
}
