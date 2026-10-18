import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/jenis_sampah_form.dart';

/// Wadah bottom sheet untuk [JenisSampahForm].
///
/// Hanya chrome: sudut, latar, penghindaran papan tik, judul dengan pegangan
/// tarik, dan arti "tutup" di sini — yaitu mem-pop route sheet. Isi formnya
/// sendiri tinggal di [JenisSampahForm], yang juga dipakai sebagai panel di
/// samping daftar pada jendela expanded.
class TambahJenisSampahBottomSheet extends StatelessWidget {
  final HargaEntity? initialData;
  final HargaCubit? hargaCubit;

  /// Sumber waktu "sekarang", dapat diganti di test.
  final DateTime Function() now;

  const TambahJenisSampahBottomSheet({
    super.key,
    this.initialData,
    this.hargaCubit,
    this.now = DateTime.now,
  });

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BottomSheetHeader(title: JenisSampahForm.titleFor(initialData)),
          const SizedBox(height: 24),
          JenisSampahForm(
            initialData: initialData,
            hargaCubit: hargaCubit,
            now: now,
            onSaved: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
