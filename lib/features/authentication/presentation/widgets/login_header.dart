import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key, this.large = false});

  /// Layar lebar: kolom kiri hanya berisi merek, jadi logo dan judulnya
  /// dibesarkan untuk mengisinya.
  final bool large;

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
          height: large ? 160 : 96,
          semanticsLabel: 'Logo PILAH',
        ),
        SizedBox(height: large ? 32 : 24),
        // Title
        Text(
          'PILAH',
          style: AppTextStyle.headline1.copyWith(
            fontWeight: AppFontWeight.bold,
            fontSize: large ? 48 : 32,
          ),
        ),
        SizedBox(height: large ? 12 : 8),
        // Subtitle
        Text(
          'Sistem Manajemen Bank Sampah',
          style: AppTextStyle.small.copyWith(
            color: AppColors.grey100,
            fontSize: large ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
