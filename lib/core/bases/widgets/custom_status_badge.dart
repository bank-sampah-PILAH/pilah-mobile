import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

class CustomStatusBadge extends StatelessWidget {
  final bool? isActive;
  final String? statusText;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomStatusBadge({
    super.key,
    this.isActive,
    this.statusText,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    if (isActive != null) {
      if (isActive!) {
        bg = const Color(0xFFDCFCE7); // green-100
        text = const Color(0xFF166534); // green-800
        label = 'Aktif';
      } else {
        bg = const Color(0xFFFEE2E2); // red-100
        text = const Color(0xFF991B1B); // red-800
        label = 'Nonaktif';
      }
    } else {
      bg = backgroundColor ?? AppColors.greenLight;
      text = textColor ?? AppColors.greenDark;
      label = statusText ?? '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyle.extraSmall.copyWith(
          color: text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
