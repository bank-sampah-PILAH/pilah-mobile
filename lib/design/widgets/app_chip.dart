import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// The pill used for filters and tabs: solid green when [selected], light grey
/// otherwise.
///
/// Screen readers hear it as a button that is, or is not, selected (with the
/// [count] read after the label), it shows a ripple when touched, and its hit
/// area is 48 dp tall as Android asks. Use it instead of building a pill out
/// of a `GestureDetector` and a `Container`.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// A small count after the label, such as how many items the filter holds.
  final int? count;

  /// For a chip on a coloured header: white when selected, translucent white
  /// otherwise (readable on the primary green).
  final bool onColor;

  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  }) : onColor = false;

  const AppChip.onColor({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  }) : onColor = true;

  @override
  Widget build(BuildContext context) {
    final color = onColor
        ? (selected ? AppColors.greenDark : Colors.white)
        : (selected ? Colors.white : AppColors.grey100);
    final background = onColor
        ? (selected ? Colors.white : Colors.white.withValues(alpha: 0.15))
        : (selected ? AppColors.greenDark : AppColors.fill);
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: count == null ? label : '$label, $count',
      onTap: onTap,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: AppTextStyle.small.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.extraSmall.copyWith(
                            color: selected ? AppColors.greenDark : color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
