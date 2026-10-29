import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// A single row in a money-activity list (setoran, pencairan, …): avatar,
/// title/subtitle on the left, amount/captions on the right. Shared so every
/// riwayat screen renders the same shape instead of a bespoke Card per
/// feature.
class ActivityItem extends StatelessWidget {
  final String avatarText;
  final Color avatarColor;
  final Color avatarTextColor;
  final String title;

  /// One [Text] per entry, rendered top to bottom under [title].
  final List<String> subtitleLines;
  final String amount;

  /// Overrides the amount's color. Defaults to [AppColors.greenDark].
  final Color? amountColor;

  /// One [Text] per entry, rendered top to bottom under [amount].
  final List<String> trailingCaptions;

  /// An optional emphasized line under [trailingCaptions] (e.g. "Diperbarui").
  /// Uses [amountColor] so it reads as part of the same amount/status group.
  final String? badge;

  const ActivityItem({
    super.key,
    required this.avatarText,
    required this.avatarColor,
    required this.avatarTextColor,
    required this.title,
    required this.subtitleLines,
    required this.amount,
    this.amountColor,
    this.trailingCaptions = const [],
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = amountColor ?? AppColors.greenDark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      // Avatar, text and amount share one vertical centre, so a row with a
      // one-line subtitle and the taller amount column do not sit at the top.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: AppTextStyle.small.copyWith(
                color: avatarTextColor,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.small.copyWith(
                    fontWeight: AppFontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                for (final line in subtitleLines) ...[
                  const SizedBox(height: 4),
                  Text(
                    line,
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.grey100,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  textAlign: TextAlign.end,
                  style: AppTextStyle.small.copyWith(
                    color: accentColor,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                if (trailingCaptions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  // Date and time share a line; they wrap only when the row
                  // is too narrow for both.
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      for (var i = 0; i < trailingCaptions.length; i++) ...[
                        if (i > 0) _caption('·'),
                        _caption(trailingCaptions[i]),
                      ],
                    ],
                  ),
                ],
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    badge!,
                    style: AppTextStyle.extraSmall.copyWith(
                      color: accentColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _caption(String text) => Text(
        text,
        style: AppTextStyle.extraSmall.copyWith(color: AppColors.grey100),
      );
}
