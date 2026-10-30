import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';

class SkeletonListItem extends StatefulWidget {
  final double height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry? borderRadius;

  const SkeletonListItem({
    super.key,
    this.height = 80.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
    this.borderRadius,
  });

  @override
  State<SkeletonListItem> createState() => _SkeletonListItemState();
}

class _SkeletonListItemState extends State<SkeletonListItem> {
  bool _isDimmed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start the infinite animation loop
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _isDimmed = !_isDimmed;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isDimmed ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      child: Container(
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.grey200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
