import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo. Deliberately not wrapped in the rounded green tile the old
        // checkmark sat on — the mark carries its own colour and needs no
        // backing shape.
        //
        // Only the height is given, so the width follows the viewBox and the
        // logo cannot be stretched.
        SvgPicture.asset(
          'assets/svg/logo.svg',
          height: 96,
          semanticsLabel: 'Logo PILAH',
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
