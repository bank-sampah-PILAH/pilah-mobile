import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class SelectionFieldFrame extends StatelessWidget {
  const SelectionFieldFrame({
    super.key,
    required this.onTap,
    required this.hasError,
    required this.hasSelection,
    required this.backgroundColor,
    required this.defaultBorderColor,
    required this.errorText,
    required this.child,
  });

  final VoidCallback? onTap;
  final bool hasError;
  final bool hasSelection;
  final Color backgroundColor;
  final Color defaultBorderColor;
  final String? errorText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: hasError
                    ? AppColors.danger
                    : hasSelection
                        ? AppColors.greenDark
                        : defaultBorderColor,
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              errorText!,
              style: AppTextStyle.small.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ],
    );
  }
}
