import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/weight_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_widgets.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_balance_display.dart';

class DashboardWebKpiSection extends StatelessWidget {
  const DashboardWebKpiSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) =>
      BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final cards = _dashboardKpiCards(state);
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1100
                  ? 3
                  : constraints.maxWidth >= 640
                      ? 2
                      : 1;
              const gap = 16.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final card in cards) SizedBox(width: width, child: card),
                ],
              );
            },
          );
        },
      );
}

List<DashboardKpiCard> _dashboardKpiCards(DashboardState state) {
  final loaded = state.status == DashboardStatus.loaded;
  return [
    DashboardKpiCard(
      label: 'Saldo Tabungan Nasabah',
      value: dashboardSavingsDisplay(state),
      icon: Icons.savings_outlined,
    ),
    const DashboardKpiCard(
      label: 'Kas Operasional',
      value: dashboardOperationalCashDisplay,
      icon: Icons.account_balance_wallet_outlined,
    ),
    DashboardKpiCard(
      label: 'Nilai Setoran Bulan Ini',
      value: loaded
          ? CurrencyFormatter.formatRupiah(state.totalKasBulanIni)
          : 'Rp —',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.greenDark,
    ),
    DashboardKpiCard(
      label: 'Nasabah Aktif',
      value: loaded ? state.totalNasabahAktif.toString() : '—',
      icon: Icons.group_outlined,
      color: AppColors.greenDark,
    ),
    DashboardKpiCard(
      label: 'Total Sampah Bulan Ini',
      value: loaded ? WeightFormatter.formatKg(state.totalSampahKg) : '—',
      unit: 'kg',
      icon: Icons.inventory_2_outlined,
      color: AppColors.statOrange,
    ),
    DashboardKpiCard(
      label: 'Total Transaksi Bulan Ini',
      value: loaded ? state.totalTransaksi.toString() : '—',
      unit: 'Trx',
      icon: Icons.show_chart,
      color: AppColors.statPurple,
    ),
  ];
}
