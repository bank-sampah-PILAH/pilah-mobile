import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profile_page.dart';

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Sampah BTH',
                          style: AppTextStyle.small.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Selamat datang, Ibu Sari ',
                                style: AppTextStyle.title1.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Text('👋', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.push('/profile');
                    },
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.greenDark,
                      child: Text(
                        'IS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Total Kas Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Column(
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
                          'Rp 12.450.000',
                          style: AppTextStyle.headline1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '↑ 18% dari bulan lalu',
                          style: AppTextStyle.small.copyWith(
                            color: AppColors.greenLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.attach_money, // Using attach_money for '$'
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Statistics Row
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.group_outlined,
                    iconColor: AppColors.greenDark,
                    iconBgColor: AppColors.greenLight,
                    value: '128',
                    label: 'Nasabah Aktif',
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.statOrange,
                    iconBgColor: AppColors.statOrangeLight,
                    value: '450 kg',
                    label: 'Total Sampah',
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    icon: Icons.show_chart,
                    iconColor: AppColors.statPurple,
                    iconBgColor: AppColors.statPurpleLight,
                    value: '45 Trx',
                    label: 'Transaksi Bln Ini',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      label: Text(
                        'Setoran Baru',
                        style: AppTextStyle.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add_outlined, color: AppColors.greenDark, size: 20),
                      label: Text(
                        'Tambah\nNasabah',
                        style: AppTextStyle.small.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12), // slightly less padding since it's 2 lines
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Recent Activity Section
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
                    onPressed: () {},
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
              _buildActivityItem(
                avatarText: 'BS',
                avatarColor: AppColors.greenLight,
                avatarTextColor: AppColors.greenDark,
                title: 'Budi Santoso',
                subtitle: 'Plastik • 5.2 kg',
                amount: '+Rp 15.600',
                time: 'Hari ini, 09:45',
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                avatarText: 'SA',
                avatarColor: AppColors.avatarYellow,
                avatarTextColor: AppColors.avatarYellowText,
                title: 'Siti Aminah',
                subtitle: 'Kertas • 12.0 kg',
                amount: '+Rp 24.000',
                time: 'Kemarin, 14:20',
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                avatarText: 'AP',
                avatarColor: AppColors.statPurpleLight,
                avatarTextColor: AppColors.statPurple,
                title: 'Agus Pratama',
                subtitle: 'Logam • 2.5 kg',
                amount: '+Rp 35.000',
                time: 'Kemarin, 10:15',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyle.title1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyle.extraSmall.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String avatarText,
    required Color avatarColor,
    required Color avatarTextColor,
    required String title,
    required String subtitle,
    required String amount,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: AppTextStyle.small.copyWith(
                color: avatarTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.small.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyle.extraSmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyle.small.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
