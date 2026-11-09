import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';
import 'package:pilah_mobile/core/analytics/replay_masks.dart';

/// The small capital caption above a form field, such as "NAMA LENGKAP".
///
/// Forms of the app put the caption above the field and a hint inside it,
/// instead of a label that floats in the border.
///
/// Pass [isRequired] for a field that refuses to submit while it is empty, and
/// the caption carries a trailing `*`.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.text, {super.key, this.isRequired = false});

  final String text;

  /// Whether the field below the caption has to be filled in.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final caption = Text(
      text,
      style: AppTextStyle.extraSmall.copyWith(
        color: AppColors.grey100,
        fontWeight: AppFontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
    if (!isRequired) return RevealInReplay(child: caption);
    return RevealInReplay(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [caption, const Text('*')],
      ),
    );
  }
}
