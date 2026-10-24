import 'package:flutter/material.dart';
// CI benchmark scratch: documentation comment only, no behavior change.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/states/dashboard_state.dart';

class TotalKasCard extends ConsumerWidget {
  const TotalKasCard({super.key});

  String _display(DashboardState state) {
    switch (state.status) {
      case DashboardStatus.loading:
      case DashboardStatus.initial:
        return 'Memuat...';
      case DashboardStatus.error:
        return 'Rp —';
      case DashboardStatus.loaded:
        return CurrencyFormatter.formatRupiah(state.totalKasBulanIni);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    return Container(
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
            'TOTAL KAS BULAN INI',
            style: AppTextStyle.extraSmall.copyWith(
              color: AppColors.greenLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _display(state),
            style: AppTextStyle.headline1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total nilai transaksi bulan ini',
            style: AppTextStyle.small.copyWith(
              color: AppColors.greenLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
