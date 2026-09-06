import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class CustomOutlinedButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color textColor;
  final Color? backgroundColor;
  final IconData? icon;

  const CustomOutlinedButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.borderColor = Colors.grey,
    this.textColor = Colors.grey,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.white,
        side: BorderSide(
            color: onPressed != null ? borderColor : Colors.grey[300]!,
            width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: onPressed != null ? textColor : Colors.grey[500]),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: AppTextStyle.title1.copyWith(
              color: onPressed != null ? textColor : Colors.grey[500],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
