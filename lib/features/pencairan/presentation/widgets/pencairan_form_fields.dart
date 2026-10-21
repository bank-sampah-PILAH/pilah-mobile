import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

/// The METODE caption and a chip for each way of paying out, used by the
/// edit form.
class MetodePencairanSelector extends StatelessWidget {
  const MetodePencairanSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final MetodePencairan selected;
  final ValueChanged<MetodePencairan> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppFieldLabel('METODE'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final metode in MetodePencairan.values)
              AppChip(
                key: Key('metode-chip-${metode.name}'),
                label: metode.label,
                selected: selected == metode,
                onTap: () => onChanged(metode),
              ),
          ],
        ),
      ],
    );
  }
}

/// The TANGGAL caption and a field that shows [tanggal] and opens the picker
/// when tapped, shared by the catat and the edit forms.
class TanggalPencairanField extends StatelessWidget {
  const TanggalPencairanField({
    super.key,
    required this.tanggal,
    required this.onTap,
    this.errorText,
    this.enabled = true,
  });

  final DateTime tanggal;
  final VoidCallback onTap;
  final String? errorText;

  /// False shows the tanggal as locked, like a disabled text field: greyed
  /// out and with nothing to tap.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppFieldLabel('TANGGAL'),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('tanggal-field'),
          onTap: enabled ? onTap : null,
          child: InputDecorator(
            decoration: appInputDecoration(
              suffixIcon:
                  const Icon(Icons.calendar_month, color: AppColors.grey100),
              errorText: errorText,
            ).copyWith(enabled: enabled),
            child: Text(
              formatTanggalId(tanggal),
              style: AppTextStyle.small.copyWith(
                color: enabled ? AppColors.black : AppColors.grey100,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
