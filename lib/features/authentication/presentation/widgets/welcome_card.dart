import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Selamat datang kembali ',
                style: AppTextStyle.title1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('👋', style: TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Masuk untuk mengelola transaksi setoran, data nasabah, dan laporan bank sampah Anda.',
            style: AppTextStyle.small.copyWith(
              color: AppColors.grey100,
            ),
          ),
        ],
      ),
    );
  }
}
