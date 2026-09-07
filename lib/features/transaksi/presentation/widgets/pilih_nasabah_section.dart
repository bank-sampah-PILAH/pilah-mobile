import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_bottom_sheet.dart';

import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

class PilihNasabahSection extends StatelessWidget {
  final NasabahEntity? selectedCustomer;
  final ValueChanged<NasabahEntity> onCustomerSelected;

  final bool hasError;
  final String? errorText;

  const PilihNasabahSection({
    super.key,
    required this.selectedCustomer,
    required this.onCustomerSelected,
    this.hasError = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final result = await showModalBottomSheet<NasabahEntity>(
              context: context,
              useRootNavigator: true,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const PilihNasabahBottomSheet(),
            );
            if (result != null) {
              onCustomerSelected(result);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: hasError
                      ? const Color(0xFFDC2626) // errorColor
                      : (selectedCustomer != null
                          ? const Color(0xFF006D44)
                          : Colors.grey[300]!),
                  width: 1.5),
            ),
            child: selectedCustomer == null
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5), // grey[100]
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_outline,
                            color: Colors.grey[500], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap untuk pilih nasabah',
                          style: AppTextStyle.small.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selectedCustomer!.avatarColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          selectedCustomer!.initials,
                          style: AppTextStyle.title1.copyWith(
                            color: selectedCustomer!.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedCustomer!.name,
                              style: AppTextStyle.title1.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // The kode, not the backend UUID — this card shows
                            // the nasabah just picked from the sheet, so it has
                            // to read the same way the sheet does. Omitted
                            // entirely when the kode is missing, rather than
                            // falling back to the UUID this fix removes.
                            if (selectedCustomer!.idNasabah
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                selectedCustomer!.idNasabah,
                                style: AppTextStyle.small.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.edit_outlined, color: Colors.grey[400]),
                    ],
                  ),
          ),
        ),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              errorText!,
              style: AppTextStyle.small.copyWith(
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
