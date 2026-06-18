import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';

class NasabahPage extends StatelessWidget {
  const NasabahPage({super.key});

  static const route = '/nasabah';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const TambahNasabahBottomSheet(),
          );
        },
        backgroundColor: AppColors.greenDark,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nasabah',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '4 aktif',
                      style: AppTextStyle.small.copyWith(
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari nama atau nomor...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              
              // Filter Chips
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.greenDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Aktif',
                      style: AppTextStyle.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tidak Aktif',
                      style: AppTextStyle.small.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // List View
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
                  children: [
                    _buildNasabahCard(
                      initials: 'AR',
                      avatarColor: AppColors.greenLight,
                      textColor: AppColors.greenDark,
                      name: 'Ahmad Ridwan',
                      phone: '0812-3456-7890',
                      balance: 'Rp 450.000',
                    ),
                    const SizedBox(height: 12),
                    _buildNasabahCard(
                      initials: 'BS',
                      avatarColor: AppColors.statPurpleLight,
                      textColor: AppColors.statPurple,
                      name: 'Budi Santoso',
                      phone: '0857-1122-3344',
                      balance: 'Rp 125.500',
                    ),
                    const SizedBox(height: 12),
                    _buildNasabahCard(
                      initials: 'CW',
                      avatarColor: AppColors.avatarYellow,
                      textColor: AppColors.avatarYellowText,
                      name: 'Citra Wijaya',
                      phone: '0896-9988-7766',
                      balance: 'Rp 890.000',
                    ),
                    const SizedBox(height: 12),
                    _buildNasabahCard(
                      initials: 'EP',
                      avatarColor: const Color(0xFFE0F7FA), // cyanLight
                      textColor: const Color(0xFF00838F), // cyanDark
                      name: 'Eko Prasetyo',
                      phone: '0813-5678-9012',
                      balance: 'Rp 215.000',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNasabahCard({
    required String initials,
    required Color avatarColor,
    required Color textColor,
    required String name,
    required String phone,
    required String balance,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTextStyle.title1.copyWith(
                color: textColor,
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
                  name,
                  style: AppTextStyle.title1.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: AppTextStyle.small.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                balance,
                style: AppTextStyle.title1.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'saldo',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
