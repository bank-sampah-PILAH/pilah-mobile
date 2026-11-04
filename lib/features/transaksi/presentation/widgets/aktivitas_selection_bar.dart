import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';

/// Header mode pilih di telepon: tutup, jumlah yang dipilih, lalu aksinya:
/// Edit dan Hapus, untuk satu setoran yang dipilih.
class AktivitasSelectionBar extends ConsumerWidget {
  const AktivitasSelectionBar({
    super.key,
    required this.onEdit,
    required this.onHapus,
  });

  /// Dipanggil dengan id setoran yang dipilih.
  final ValueChanged<String> onEdit;

  /// Dipanggil dengan id setoran yang dipilih; membatalkannya (PIL-428).
  final ValueChanged<String> onHapus;

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
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              AppTapTarget(
                key: closeKey,
                onTap: notifier.clear,
                label: 'Batal memilih',
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.close, color: Colors.white),
                ),
              ),
              Expanded(
                child: Text(
                  '1 dipilih',
                  style: AppTextStyle.title1.copyWith(color: Colors.white),
                ),
              ),
              if (selected != null) ...[
                _onWhite(AppButton(
                  key: editKey,
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.compact,
                  expand: false,
                  onPressed: () => onEdit(selected),
                )),
                _onWhite(AppButton(
                  key: hapusKey,
                  label: 'Hapus',
                  icon: Icons.delete_outline,
                  variant: AppButtonVariant.destructiveOutlined,
                  size: AppButtonSize.compact,
                  expand: false,
                  onPressed: () => onHapus(selected),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Putih di atas bilah hijau, agar tombol outline (seperti di web) tetap
  /// terbaca.
  static Widget _onWhite(Widget button) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: button,
        ),
      );
}
