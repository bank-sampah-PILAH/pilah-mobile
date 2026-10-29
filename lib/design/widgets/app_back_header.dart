import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// The header of a full page that has no app bar: a grey back button and the
/// page title beside it, such as "Catat Pencairan", with optional [actions] at
/// the right end.
///
/// The back button is announced as "Kembali" and has the 48 dp hit area that
/// Android asks for. Without an [onBack] it goes back with `maybePop`, so a
/// screen that guards unsaved edits with a `PopScope` is asked first. A title
/// too long for the line ends in an ellipsis.
class AppBackHeader extends StatelessWidget {
  const AppBackHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.backKey,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Key of the back button, for a test to find it.
  final Key? backKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AppTapTarget(
            key: backKey,
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            label: 'Kembali',
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.inkSoft,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.headline1.copyWith(
                color: AppColors.black,
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.xxl,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
