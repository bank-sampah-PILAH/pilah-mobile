import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline,
          size: 16,
          color: AppColors.grey200,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Hanya untuk Pengurus & Admin terdaftar • Aman & Terenkripsi',
            textAlign: TextAlign.center,
            style: AppTextStyle.extraSmall.copyWith(
              color: AppColors.grey200,
            ),
          ),
        ),
      ],
    );
  }
}
