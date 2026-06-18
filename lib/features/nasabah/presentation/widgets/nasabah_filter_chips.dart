import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class NasabahFilterChips extends StatelessWidget {
  final bool isActiveTab;
  final ValueChanged<bool> onTabChanged;

  const NasabahFilterChips({
    super.key,
    required this.isActiveTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Emerald Eco System Design tokens
    const Color emeraldPrimary = Color(0xFF006D44);

    return Row(
      children: [
        GestureDetector(
          onTap: () => onTabChanged(true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isActiveTab ? emeraldPrimary : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Aktif',
              style: AppTextStyle.small.copyWith(
                color: isActiveTab ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onTabChanged(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: !isActiveTab ? emeraldPrimary : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Tidak Aktif',
              style: AppTextStyle.small.copyWith(
                color: !isActiveTab ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
