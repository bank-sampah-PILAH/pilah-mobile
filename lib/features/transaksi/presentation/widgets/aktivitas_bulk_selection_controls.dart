import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/widgets/app_icon_button.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/bulk_batalkan_setoran_dialog.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_selection_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';

/// Entry point to bulk selection. Choosing records never changes a setoran.
class AktivitasOptionsMenu extends ConsumerWidget {
  const AktivitasOptionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(riwayatAktivitasProvider);
    final selecting = ref.watch(aktivitasBulkSelectionProvider) != null;
    final hasSelectable = feed.status == AktivitasStatus.loaded &&
        feed.items.any((item) => item.isSelectableSetoran);
    return PopupMenuButton<String>(
      tooltip: 'Opsi',
      enabled: !selecting,
      onSelected: (_) {
        ref.read(aktivitasSelectionProvider.notifier).clear();
        ref.read(aktivitasBulkSelectionProvider.notifier).start();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'select',
          enabled: hasSelectable,
          child: const Text('Pilih Setoran'),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Opsi'),
            SizedBox(width: AppSpacing.xs),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

/// Count and an explicit action; selecting alone never submits a void.
class AktivitasBulkSelectionBar extends ConsumerWidget {
  const AktivitasBulkSelectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(aktivitasBulkSelectionProvider);
    if (selected == null) return const SizedBox.shrink();
    if (context.layoutBreakpoint == LayoutBreakpoint.compact) {
      return AktivitasSelectionBar.bulk(
        count: selected.length,
        onClose: ref.read(aktivitasBulkSelectionProvider.notifier).clear,
        action: _hapus(context, selected, compact: true),
      );
    }
    return ContentInset(
        child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.webGutter,
        vertical: AppSpacing.md,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text('${selected.length} dipilih',
                    style: AppTextStyle.title1),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _hapus(context, selected),
            const SizedBox(width: AppSpacing.md),
            AppIconButton(
              icon: Icons.close,
              tooltip: 'Batal memilih setoran',
              onPressed:
                  ref.read(aktivitasBulkSelectionProvider.notifier).clear,
            ),
          ],
        ),
      ]),
    ));
  }

  Widget _hapus(BuildContext context, Set<String> selected,
          {bool compact = false}) =>
      AppButton(
        label: 'Hapus (${selected.length})',
        icon: Icons.delete_outline,
        variant: AppButtonVariant.destructiveOutlined,
        expand: false,
        size: compact ? AppButtonSize.compact : AppButtonSize.regular,
        onPressed: selected.isEmpty
            ? null
            : () => showBulkBatalkanSetoranDialog(context),
      );
}
