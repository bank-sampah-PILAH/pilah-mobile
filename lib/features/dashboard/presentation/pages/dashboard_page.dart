import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_statistics_section.dart';
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
              const DashboardStatisticsSection(),
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
