import 'package:flutter/material.dart';
// CI benchmark scratch: documentation comment only, no behavior change.
import 'package:pilah_mobile/design/widgets/app_chip.dart';

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
    Widget chip(String label, bool? value) => AppChip(
          label: label,
          selected: activeTab == value,
          onTap: () => onTabChanged(value),
        );

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
