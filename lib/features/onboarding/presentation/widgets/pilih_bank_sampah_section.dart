import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/selection_field_frame.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/pilih_bank_sampah_bottom_sheet.dart';

/// The tappable field on [RegisterNasabahScreen] that opens
/// [PilihBankSampahBottomSheet] and shows the picked bank sampah.
class PilihBankSampahSection extends StatelessWidget {
  final BankSampahDirectoryEntity? selectedBank;
  final ValueChanged<BankSampahDirectoryEntity> onBankSelected;
  final bool hasError;
  final String? errorText;

  /// False when registration is locked (PIL-204: one membership per
  /// nasabah for now) — the field renders but no longer opens the picker.
  final bool enabled;

  /// Bank sampah ids to hide from the picker, e.g. ones already joined.
  final Set<String> excludedBankIds;

  const PilihBankSampahSection({
    super.key,
    required this.selectedBank,
    required this.onBankSelected,
    this.hasError = false,
    this.errorText,
    this.enabled = true,
    this.excludedBankIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SelectionFieldFrame(
      onTap: !enabled
          ? null
          : () async {
              final result =
                  await showAdaptiveSurface<BankSampahDirectoryEntity>(
                context,
                builder: (context) => PilihBankSampahBottomSheet(
                  excludedBankIds: excludedBankIds,
                ),
              );
              if (result != null) onBankSelected(result);
            },
      hasError: hasError,
      hasSelection: selectedBank != null,
      backgroundColor: enabled ? Colors.white : AppColors.fill,
      defaultBorderColor: Colors.grey[300]!,
      errorText: errorText,
      child: selectedBank == null
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.recycling_outlined,
                      color: Colors.grey[500], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap untuk pilih bank sampah',
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
                    color: AppColors.greenDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child:
                      const Icon(Icons.recycling, color: AppColors.greenDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedBank!.nama,
                        style: AppTextStyle.title1.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedBank!.kota.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          selectedBank!.kota,
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
    );
  }
}
