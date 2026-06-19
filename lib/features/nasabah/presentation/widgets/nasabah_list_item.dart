import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';

class NasabahListItem extends StatelessWidget {
  final bool isActive;
  final String initials;
  final Color avatarColor;
  final Color textColor;
  final String name;
  final String phone;
  final String balance;

  const NasabahListItem({
    super.key,
    required this.isActive,
    required this.initials,
    required this.avatarColor,
    required this.textColor,
    required this.name,
    required this.phone,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DetailNasabahBottomSheet(
            customerData: {
              'isActive': isActive,
              'initials': initials,
              'name': name,
              'phone': phone,
              'balance': balance,
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTextStyle.title1.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: AppTextStyle.title1.copyWith(
                          color: isActive ? Colors.black87 : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (!isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Nonaktif',
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: AppTextStyle.small.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  balance,
                  style: AppTextStyle.title1.copyWith(
                    color: isActive ? AppColors.greenDark : Colors.grey[500],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'saldo',
                  style: AppTextStyle.extraSmall.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
