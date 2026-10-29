import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/picker_presentation.dart';
import 'package:pilah_mobile/design/widgets/selection_field_frame.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_picker.dart';

import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

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
    return SelectionFieldFrame(
      onTap: () async {
        // Bottom sheet pada telepon, dialog pada peramban. Wadahnya
        // dipilih oleh showAdaptivePicker; di sini hanya isinya.
        final result = await showAdaptivePicker<NasabahEntity>(
          context: context,
          builder: (context, presentation) =>
              PilihNasabahPicker(presentation: presentation),
        );
        if (result != null) onCustomerSelected(result);
      },
      hasError: hasError,
      hasSelection: selectedCustomer != null,
      backgroundColor: Colors.white,
      defaultBorderColor: AppColors.border,
      errorText: errorText,
      child: selectedCustomer == null
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.fill,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      color: AppColors.grey100, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap untuk pilih nasabah',
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.grey100,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.grey200),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selectedCustomer!.avatarColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Show the kode, not the backend UUID.
                      if (selectedCustomer!.idNasabah.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          selectedCustomer!.idNasabah,
                          style: AppTextStyle.small.copyWith(
                            color: AppColors.grey100,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: AppColors.grey200),
              ],
            ),
    );
  }
}
