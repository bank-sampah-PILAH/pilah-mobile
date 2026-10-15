import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/utils/avatar_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

/// One row in a bank-sampah directory: white card, initials avatar, name and
/// a one-line subtitle, with a trailing slot for whatever the caller shows
/// (a distance pill, a chevron, nothing).
///
/// Shared by the search list (PIL-308) and the pick-a-bank sheet (PIL-309) —
/// they showed the same card with slightly drifted values; keeping one
/// widget keeps them identical by construction.
class BankItemCard extends StatelessWidget {
  final BankSampahDirectoryEntity bank;

  /// The line under the name, e.g. "kota · alamat" or just the kota.
  final String subtitle;

  /// Trailing content after the text column (a PillTag, a chevron, null).
  final Widget? trailing;

  const BankItemCard({
    super.key,
    required this.bank,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              initialsOf(bank.nama),
              style: AppTextStyle.title1.copyWith(
                color: AppColors.greenDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.nama,
                  style: AppTextStyle.title1.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyle.small.copyWith(
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
