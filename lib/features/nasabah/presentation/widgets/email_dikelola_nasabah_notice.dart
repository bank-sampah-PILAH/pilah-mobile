import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// A display-only notice; the server remains authoritative for linked emails.
class EmailDikelolaNasabahNotice extends StatelessWidget {
  const EmailDikelolaNasabahNotice({
    super.key,
    required this.backgroundColor,
    required this.titleStyle,
    required this.messageStyle,
    required this.message,
  });

  final Color backgroundColor;
  final TextStyle titleStyle;
  final TextStyle messageStyle;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.greenDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email dikelola oleh nasabah',
                  style: titleStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: messageStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
