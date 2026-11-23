import 'package:flutter/material.dart';

/// Makes [child] a proper button: screen readers hear a button (with [label]
/// when the child has no text of its own), it shows a ripple, and its hit area
/// is at least [minSize] dp square as Android asks, even for a 16 dp icon.
///
/// Use it instead of a bare `GestureDetector`, which has no role, no label and
/// no feedback. For a pill-shaped filter use `AppChip`; for a white card use
/// `AppTappableCard`.
class AppTapTarget extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  /// What a screen reader says. Leave null when [child] has its own text.
  final String? label;

  /// Reports a selected state, for an option in a group.
  final bool? selected;

  /// Marks the target as one of several mutually exclusive options.
  final bool inGroup;

  final double minSize;
  final BorderRadius? borderRadius;

  const AppTapTarget({
    super.key,
    required this.onTap,
    required this.child,
    this.label,
    this.selected,
    this.inGroup = false,
    this.minSize = 48,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final target = Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      inMutuallyExclusiveGroup: inGroup ? true : null,
      label: label,
      onTap: onTap,
      excludeSemantics: label != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
    // One node that reads the child's own text, unless a label replaces it.
    return label == null ? MergeSemantics(child: target) : target;
  }
}
