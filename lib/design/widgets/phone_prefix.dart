import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// The "+62 |" before a phone number field. Pass it as the `prefixIcon` of
/// [appInputDecoration].
class PhonePrefix extends StatelessWidget {
  const PhonePrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+62',
            style: AppTextStyle.headline3.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            key: const Key('phone-divider'),
            height: 24,
            width: 1,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
