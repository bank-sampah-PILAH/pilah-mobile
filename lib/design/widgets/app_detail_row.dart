import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';

/// A label on the left and its value on the right, one line of a detail sheet
/// such as "Metode  Tunai". A long value wraps.
class AppDetailRow extends StatelessWidget {
  const AppDetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: NasabahStyle.text(13, color: NasabahStyle.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: NasabahStyle.text(13, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
