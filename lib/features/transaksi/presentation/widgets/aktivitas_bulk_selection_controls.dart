import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/widgets/app_icon_button.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/batalkan_setoran_dialog.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/edit_setoran_sheet.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/bulk_batalkan_setoran_dialog.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_selection_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';

/// Header while setoran are selected: count and an explicit action; selecting
/// alone never submits a void. One selection edits or voids that setoran as
/// before (PIL-427/428); several void together (PIL-429).
class AktivitasBulkSelectionBar extends ConsumerWidget {
  const AktivitasBulkSelectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(aktivitasSelectionProvider);
    if (selected == null) return const SizedBox.shrink();
    final single = selected.length == 1 ? selected.single : null;
    final feed = ref.watch(riwayatAktivitasProvider);
    final total = feed.totalCount;
    final otherPages = total > feed.items.length;
    if (context.layoutBreakpoint == LayoutBreakpoint.compact) {
      if (single != null) {
        return AktivitasSelectionBar(
          onEdit: (id) => showEditSetoranSheet(context, id),
          onHapus: (id) => showBatalkanSetoranDialog(context, id),
        );
      }
      return AktivitasSelectionBar.bulk(
        count: selected.length,
        onClose: ref.read(aktivitasSelectionProvider.notifier).clear,
        action: _hapus(context, selected, compact: true),
      );
    }
    return ContentInset(
        child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.webGutter,
        vertical: AppSpacing.md,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${selected.length} dipilih',
                        style: AppTextStyle.title1),
                    if (otherPages)
                      Text(
                        'Hanya di halaman ini, dari $total transaksi',
                        style: AppTextStyle.small
                            .copyWith(color: AppColors.grey100),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _hapus(context, selected, single: single),
            const SizedBox(width: AppSpacing.md),
            AppIconButton(
              icon: Icons.close,
              tooltip: 'Batal memilih setoran',
              onPressed: ref.read(aktivitasSelectionProvider.notifier).clear,
            ),
          ],
        ),
      ]),
    ));
  }

  Widget _hapus(BuildContext context, Set<String> selected,
          {bool compact = false, String? single}) =>
      AppButton(
        label: 'Hapus (${selected.length})',
        icon: Icons.delete_outline,
        variant: AppButtonVariant.destructiveOutlined,
        expand: false,
        size: compact ? AppButtonSize.compact : AppButtonSize.regular,
        onPressed: () => single != null
            ? showBatalkanSetoranDialog(context, single)
            : showBulkBatalkanSetoranDialog(context),
      );
}
