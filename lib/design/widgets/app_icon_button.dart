import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';

/// An icon-only action that sits in a row with [AppButton]s, such as export
/// next to a period button: a white square, as tall as a button, rounded 12
/// with a hairline border. [tooltip] is also its label for screen readers.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: SizedBox.square(
              dimension: AppButton.height,
              child: Icon(icon, size: 22, color: AppColors.inkSoft),
            ),
          ),
        ),
      ),
    );
  }
}
