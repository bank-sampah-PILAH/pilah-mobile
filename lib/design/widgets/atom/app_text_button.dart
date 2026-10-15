import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/text_style.dart';
import '../app_tap_target.dart';

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTapTarget(
      onTap: onTap,
      child: Text(
        label,
        style: AppTextStyle.regularSemiBold.copyWith(
          color: AppColors.greenDark,
        ),
      ),
    );
  }
}
