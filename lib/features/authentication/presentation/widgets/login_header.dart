import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo Section
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.greenDark,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        // Title
        Text(
          'PILAH',
          style: AppTextStyle.headline1.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 8),
        // Subtitle
        Text(
          'Sistem Manajemen Bank Sampah',
          style: AppTextStyle.small.copyWith(
            color: AppColors.grey100,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
