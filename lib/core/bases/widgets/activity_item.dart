import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: AppTextStyle.small.copyWith(
                color: avatarTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.small.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                for (final line in subtitleLines) ...[
                  const SizedBox(height: 4),
                  Text(
                    line,
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyle.small.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              for (final caption in trailingCaptions) ...[
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: AppTextStyle.extraSmall.copyWith(
                    color: Colors.grey[600],
                  ),
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
        ],
      ),
    );
  }
}
