import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';

/// Header mode pilih di telepon: tutup, jumlah yang dipilih, lalu aksinya.
/// Saat ini aksinya hanya Edit, untuk satu setoran yang dipilih.
class AktivitasSelectionBar extends ConsumerWidget {
  const AktivitasSelectionBar({super.key, required this.onEdit});

  /// Dipanggil dengan id setoran yang dipilih.
  final ValueChanged<String> onEdit;

  static const editKey = ValueKey('selection-edit');
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
              if (selected != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  // Putih di atas bilah hijau, agar tombol outline hijau
                  // (seperti di web) tetap terbaca.
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: AppButton(
                      key: editKey,
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.compact,
                      expand: false,
                      onPressed: () => onEdit(selected),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
