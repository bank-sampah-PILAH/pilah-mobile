import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// The small capital caption above a form field, such as "NAMA LENGKAP".
///
/// Forms of the app put the caption above the field and a hint inside it,
/// instead of a label that floats in the border.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyle.extraSmall.copyWith(
        color: AppColors.grey100,
        fontWeight: AppFontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}
