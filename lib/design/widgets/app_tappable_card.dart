import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// The white rounded card with a soft shadow that opens something when tapped
/// (a nasabah, a price, a bank sampah). It is announced as a button that reads
/// its own content, and it ripples inside the card.
class AppTappableCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppTappableCard({
    super.key,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // A transparent Material inside the decoration, so the ripple is drawn
          // on top of the white fill instead of underneath it.
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_radius),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
