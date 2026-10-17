import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';

class NasabahActivityCard extends StatelessWidget {
  const NasabahActivityCard({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    this.isWithdrawal = false,
    this.onTap,
  });

  final String title;
  final DateTime? date;
  final String amount;
  final bool isWithdrawal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final local = date?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: NasabahCard(
          padding: 12,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.greenLight,
                child: Icon(
                  isWithdrawal ? Icons.south_west : Icons.recycling_outlined,
                  size: 18,
                  color: AppColors.greenDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: NasabahStyle.text(14, weight: FontWeight.w500)),
                    if (local != null)
                      Text(
                        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} · ${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}',
                        style: NasabahStyle.text(12, color: NasabahStyle.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isWithdrawal ? '−' : '+'} $amount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NasabahStyle.text(
                  13,
                  weight: FontWeight.w600,
                  color:
                      isWithdrawal ? Colors.red.shade700 : AppColors.greenDark,
                  tabularFigures: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
