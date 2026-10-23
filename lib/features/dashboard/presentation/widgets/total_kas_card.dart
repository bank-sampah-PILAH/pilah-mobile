import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_balance_display.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_widgets.dart';

class TotalKasCard extends StatelessWidget {
  const TotalKasCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.greenDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Tabungan Nasabah',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.greenLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dashboardSavingsDisplay(state),
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total saldo nasabah saat ini',
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.greenLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const DashboardKpiCard(
              label: 'Kas Operasional',
              value: dashboardOperationalCashDisplay,
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 16),
            DashboardKpiCard(
              label: 'Nilai Setoran Bulan Ini',
              value: state.isLoaded
                  ? CurrencyFormatter.formatRupiah(state.totalKasBulanIni)
                  : 'Rp —',
              icon: Icons.receipt_long_outlined,
            ),
          ],
        );
      },
    );
  }
}
