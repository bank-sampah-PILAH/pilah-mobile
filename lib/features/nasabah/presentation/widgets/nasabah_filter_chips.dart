import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// `true` = Aktif, `false` = Tidak Aktif, `null` = Menunggu (PIL-188).
class NasabahFilterChips extends StatelessWidget {
  final bool? activeTab;
  final ValueChanged<bool?> onTabChanged;

  const NasabahFilterChips({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Local tokens (candidates for AppColors)

    Widget chip(String label, bool? value) {
      final selected = activeTab == value;
      return GestureDetector(
        onTap: () => onTabChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenDark : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTextStyle.small.copyWith(
              color: selected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Aktif', true),
        const SizedBox(width: 8),
        chip('Tidak Aktif', false),
        const SizedBox(width: 8),
        chip('Menunggu', null),
      ],
    );
  }
}
