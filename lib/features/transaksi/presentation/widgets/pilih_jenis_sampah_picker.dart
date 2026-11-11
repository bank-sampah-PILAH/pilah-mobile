import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/picker_presentation.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/models/jenis_sampah_query.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/states/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/jenis_sampah_filter_bar.dart';

/// Isi picker jenis sampah di setoran: cari, saring per kategori, urutkan, lalu
/// pilih satu. Pop [HargaEntity] yang dipilih.
///
/// Wadahnya (bottom sheet atau dialog) datang dari [showAdaptivePicker].
/// Aturan cari, filter, dan urut ada di [JenisSampahQuery], bukan di sini.
class PilihJenisSampahPicker extends ConsumerStatefulWidget {
  const PilihJenisSampahPicker({
    super.key,
    this.selectedId,
    this.presentation = PickerPresentation.bottomSheet,
  });

  final String? selectedId;
  final PickerPresentation presentation;

  @override
  ConsumerState<PilihJenisSampahPicker> createState() =>
      _PilihJenisSampahPickerState();
}

class _PilihJenisSampahPickerState
    extends ConsumerState<PilihJenisSampahPicker> {
  JenisSampahQuery _query = const JenisSampahQuery();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hargaProvider);
    final katalog = ref.read(hargaProvider.notifier).activeJenisSampah;
    final kategori = kategoriTersedia(katalog);
    // Kategori yang hilang dari data (mis. setelah dimuat ulang) tidak boleh
    // menyisakan filter yang tak bisa dibatalkan.
    final query = _query.sesuaikanKategori(kategori);
    final hasil = query.apply(katalog);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BottomSheetHeader(
          title: 'Pilih Jenis Sampah',
          showDragHandle: widget.presentation.showsDragHandle,
        ),
        // Sama dengan sheet berformulir lain (Tambah Jenis Sampah, Filter
        // Tanggal): judul dan isi tidak boleh menempel.
        const SizedBox(height: AppSpacing.xl),
        JenisSampahFilterBar(
          query: query,
          kategori: kategori,
          onChanged: (q) => setState(() => _query = q),
        ),
        const SizedBox(height: 16),
        Expanded(child: _isi(state, katalog, hasil, query)),
      ],
    );
  }

  Widget _isi(HargaState state, List<HargaEntity> katalog,
      List<HargaEntity> hasil, JenisSampahQuery query) {
    if (katalog.isEmpty) {
      if (state is HargaLoading || state is HargaInitial) {
        return const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      return _pesan(state is HargaError
          ? state.message
          : 'Belum ada jenis sampah aktif.');
    }
    if (hasil.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pesan('Jenis sampah tidak ditemukan.'),
            if (!query.isDefault)
              TextButton(
                onPressed: () =>
                    setState(() => _query = const JenisSampahQuery()),
                child: const Text('Reset filter'),
              ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: hasil.length,
      itemBuilder: (context, i) => _baris(context, hasil[i]),
    );
  }

  Widget _pesan(String teks) => Center(
        child: Text(
          teks,
          textAlign: TextAlign.center,
          style: AppTextStyle.small.copyWith(color: AppColors.grey100),
        ),
      );

  Widget _baris(BuildContext context, HargaEntity item) {
    final dipilih = item.id == widget.selectedId;
    return InkWell(
      key: Key('jenis-sampah-${item.id}'),
      onTap: () => Navigator.of(context).pop(item),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, color: item.iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.black,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  Text(
                    labelKategori(item.category),
                    style: AppTextStyle.extraSmall
                        .copyWith(color: AppColors.grey100),
                  ),
                ],
              ),
            ),
            Text(
              '${item.priceFormatted}/kg',
              style: AppTextStyle.small.copyWith(color: AppColors.greenDark),
            ),
            if (dipilih) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: AppColors.greenDark, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
