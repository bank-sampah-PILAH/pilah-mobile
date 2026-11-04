import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';

/// Shared phone selection header: close, count, then actions. Single selection
/// supplies Edit/Hapus; bulk selection supplies its count and Hapus action.
class AktivitasSelectionBar extends ConsumerWidget {
  const AktivitasSelectionBar({
    super.key,
    required this.onEdit,
    required this.onHapus,
  })  : count = null,
        onClose = null,
        action = null;

  const AktivitasSelectionBar.bulk({
    super.key,
    required this.count,
    required this.onClose,
    required this.action,
  })  : onEdit = null,
        onHapus = null;

  final int? count;
  final VoidCallback? onClose;
  final Widget? action;

  /// Dipanggil dengan id setoran yang dipilih.
  final ValueChanged<String>? onEdit;

  /// Dipanggil dengan id setoran yang dipilih; membatalkannya (PIL-428).
  final ValueChanged<String>? onHapus;

  static const editKey = ValueKey('selection-edit');
  static const hapusKey = ValueKey('selection-hapus');
  static const closeKey = ValueKey('selection-close');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(aktivitasSelectionProvider);
    final notifier = ref.read(aktivitasSelectionProvider.notifier);
    return Material(
      color: AppColors.greenDark,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Tooltip(
                message:
                    count == null ? 'Batal memilih' : 'Batal memilih setoran',
                child: AppTapTarget(
                  key: closeKey,
                  onTap: onClose ?? notifier.clear,
                  label:
                      count == null ? 'Batal memilih' : 'Batal memilih setoran',
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: AppSpacing.sm,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${count ?? 1} dipilih',
                        style:
                            AppTextStyle.title1.copyWith(color: Colors.white),
                      ),
                    ),
                    Wrap(children: [
                      if (action != null) _onWhite(action!),
                      if (count == null && selected != null) ...[
                        _onWhite(AppButton(
                          key: editKey,
                          label: 'Edit',
                          icon: Icons.edit_outlined,
                          variant: AppButtonVariant.outlined,
                          size: AppButtonSize.compact,
                          expand: false,
                          onPressed: () => onEdit!(selected),
                        )),
                        _onWhite(AppButton(
                          key: hapusKey,
                          label: 'Hapus',
                          icon: Icons.delete_outline,
                          variant: AppButtonVariant.destructiveOutlined,
                          size: AppButtonSize.compact,
                          expand: false,
                          onPressed: () => onHapus!(selected),
                        )),
                      ],
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Putih di atas bilah hijau, agar tombol outline (seperti di web) tetap
  /// terbaca.
  static Widget _onWhite(Widget button) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: button,
        ),
      );
}
