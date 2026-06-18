import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

class LoginBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const LoginBackgroundWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Background Blob (Top Right)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Background Blob (Bottom Left)
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main Content
          child,
        ],
      ),
    );
  }
}
