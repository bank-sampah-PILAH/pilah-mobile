import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/activity_item.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terbaru',
              style: AppTextStyle.title1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/laporan'),
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.greenDark),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // List Items
        const ActivityItem(
          avatarText: 'BS',
          avatarColor: AppColors.greenLight,
          avatarTextColor: AppColors.greenDark,
          title: 'Budi Santoso',
          subtitle: 'Plastik • 5.2 kg',
          amount: '+Rp 15.600',
          time: 'Hari ini, 09:45',
        ),
        const SizedBox(height: 12),
        const ActivityItem(
          avatarText: 'SA',
          avatarColor: AppColors.avatarYellow,
          avatarTextColor: AppColors.avatarYellowText,
          title: 'Siti Aminah',
          subtitle: 'Kertas • 12.0 kg',
          amount: '+Rp 24.000',
          time: 'Kemarin, 14:20',
        ),
        const SizedBox(height: 12),
        const ActivityItem(
          avatarText: 'AP',
          avatarColor: AppColors.statPurpleLight,
          avatarTextColor: AppColors.statPurple,
          title: 'Agus Pratama',
          subtitle: 'Logam • 2.5 kg',
          amount: '+Rp 35.000',
          time: 'Kemarin, 10:15',
        ),
      ],
    );
  }
}
