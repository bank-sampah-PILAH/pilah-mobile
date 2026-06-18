import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/total_kas_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const route = '/dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardHeader(),
              const SizedBox(height: 24),
              const TotalKasCard(),
              const SizedBox(height: 24),
              
              // Statistics Row
              Row(
                children: const [
                  StatCard(
                    icon: Icons.group_outlined,
                    iconColor: AppColors.greenDark,
                    iconBgColor: AppColors.greenLight,
                    value: '128',
                    label: 'Nasabah Aktif',
                  ),
                  SizedBox(width: 12),
                  StatCard(
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.statOrange,
                    iconBgColor: AppColors.statOrangeLight,
                    value: '450 kg',
                    label: 'Total Sampah',
                  ),
                  SizedBox(width: 12),
                  StatCard(
                    icon: Icons.show_chart,
                    iconColor: AppColors.statPurple,
                    iconBgColor: AppColors.statPurpleLight,
                    value: '45 Trx',
                    label: 'Transaksi Bln Ini',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const DashboardActionButtons(),
              const SizedBox(height: 32),
              
              const RecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }
}
