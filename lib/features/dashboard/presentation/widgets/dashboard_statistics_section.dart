import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/laporan/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/laporan/presentation/cubit/transaksi_state.dart';

class DashboardStatisticsSection extends StatelessWidget {
  const DashboardStatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NasabahCubit, NasabahState>(
      builder: (context, nasabahState) {
        int activeNasabah = 0;
        if (nasabahState is NasabahLoaded) {
          for (var nasabah in nasabahState.nasabahList) {
            if (nasabah.isActive == true) {
              activeNasabah++;
            }
          }
        }

        return BlocBuilder<TransaksiCubit, TransaksiState>(
          builder: (context, transaksiState) {
            int totalBerat = 0;
            int totalTrx = 0;
            
            if (transaksiState is TransaksiLoaded) {
              for (var group in transaksiState.transaksiList) {
                var transactions = group['transactions'] as List<dynamic>;
                totalTrx += transactions.length;
                for (var trx in transactions) {
                  var items = trx['items'] as List<dynamic>? ?? [];
                  for (var item in items) {
                    String beratStr = item['berat']?.toString() ?? '0 kg';
                    String clean = beratStr.replaceAll(RegExp(r'[^0-9]'), '');
                    totalBerat += int.tryParse(clean) ?? 0;
                  }
                }
              }
            }

            return Row(
              children: [
                StatCard(
                  icon: Icons.group_outlined,
                  iconColor: AppColors.greenDark,
                  iconBgColor: AppColors.greenLight,
                  value: activeNasabah.toString(),
                  label: 'Nasabah Aktif',
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppColors.statOrange,
                  iconBgColor: AppColors.statOrangeLight,
                  value: '$totalBerat kg',
                  label: 'Total Sampah',
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.show_chart,
                  iconColor: AppColors.statPurple,
                  iconBgColor: AppColors.statPurpleLight,
                  value: '$totalTrx Trx',
                  label: 'Total Transaksi',
                ),
              ],
            );
          },
        );
      },
    );
  }
}
