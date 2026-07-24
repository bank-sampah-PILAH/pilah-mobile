import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/weight_formatter.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';

class DashboardStatisticsSection extends StatelessWidget {
  const DashboardStatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final loaded = state.status == DashboardStatus.loaded;
        return Row(
          children: [
            StatCard(
              icon: Icons.group_outlined,
              iconColor: AppColors.greenDark,
              iconBgColor: AppColors.greenLight,
              value: loaded ? state.totalNasabahAktif.toString() : '—',
              label: 'Nasabah Aktif',
            ),
            const SizedBox(width: 12),
            StatCard(
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.statOrange,
              iconBgColor: AppColors.statOrangeLight,
              value: loaded ? '${WeightFormatter.formatKg(state.totalSampahKg)} kg' : '—',
              label: 'Total Sampah',
            ),
            const SizedBox(width: 12),
            StatCard(
              icon: Icons.show_chart,
              iconColor: AppColors.statPurple,
              iconBgColor: AppColors.statPurpleLight,
              value: loaded ? '${state.totalTransaksi} Trx' : '—',
              label: 'Total Transaksi',
            ),
          ],
        );
      },
    );
  }
}
