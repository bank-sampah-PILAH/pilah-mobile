import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_urutan.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';

/// The same visible ordering control is used by the phone list and web table.
class NasabahOrderControls extends ConsumerWidget {
  const NasabahOrderControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(nasabahProvider);
    final notifier = ref.read(nasabahProvider.notifier);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Semantics(
            label: 'Urutan nasabah',
            child: DropdownButton<NasabahUrutan>(
              key: const ValueKey('nasabah-order'),
              value: notifier.urutan,
              isExpanded: true,
              borderRadius: BorderRadius.circular(AppRadius.md),
              items: [
                for (final urutan in NasabahUrutan.values)
                  DropdownMenuItem(value: urutan, child: Text(urutan.label)),
              ],
              onChanged: (urutan) {
                if (urutan != null) notifier.setUrutan(urutan);
              },
            ),
          ),
        ),
        if (notifier.hasActiveFilters)
          AppButton(
            label: 'Atur ulang',
            variant: AppButtonVariant.text,
            size: AppButtonSize.compact,
            expand: false,
            onPressed: notifier.resetFilters,
          ),
      ],
    );
  }
}
