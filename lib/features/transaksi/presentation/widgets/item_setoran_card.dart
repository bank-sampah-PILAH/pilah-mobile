import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/core/utils/formatter/weight_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/setoran_subtotal.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/layout/picker_presentation.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_jenis_sampah_picker.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

class ItemSetoranCard extends StatelessWidget {
  final int index;
  final bool? isWebOverride;
  final Map<String, dynamic> itemData;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;

  /// Harga per kg yang dipakai ketika pengelola memilih jenis. Bawaannya harga
  /// hari ini; edit setoran memberi harga pada tanggal setoran.
  final int Function(HargaEntity jenis)? hargaFor;

  /// Dipanggil ketika pengelola menekan Enter pada kotak berat. Opsional, jadi
  /// pemanggil yang tidak peduli tidak perlu berubah.
  final VoidCallback? onSubmitted;
  final bool hasError;
  final String? errorText;

  const ItemSetoranCard({
    super.key,
    required this.index,
    this.isWebOverride,
    required this.itemData,
    required this.onChanged,
    required this.onDelete,
    this.hargaFor,
    this.onSubmitted,
    this.hasError = false,
    this.errorText,
  });

  static const Color errorLight = AppColors.dangerLight;
  static const Color errorColor = AppColors.danger;

  @override
  Widget build(BuildContext context) {
    final selectedType = itemData['jenis'] as String?;
    final harga = itemData['harga'] as int? ?? 0;
    final berat = itemData['berat'] as num? ?? 1.0;
    final subtotal = setoranSubtotal(harga, berat);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Dropdown & Delete Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: hasError ? errorColor : AppColors.border),
                  ),
                  child: Consumer(
                    builder: (context, ref, child) {
                      ref.watch(hargaProvider);
                      // Source the options from the full active list rather than
                      // the price-list page's tab/search-filtered state, so the
                      // picker always offers every active jenis sampah. The
                      // provider watch rebuilds this when loadHarga() completes.
                      final List<HargaEntity> activeList =
                          ref.read(hargaProvider.notifier).activeJenisSampah;
                      // A stale selection no longer in the list (e.g. a jenis
                      // that was deactivated) shows as unselected.
                      final selected = activeList
                          .where((t) => t.name == selectedType)
                          .firstOrNull;

                      return InkWell(
                        key: const Key('pilih-jenis-sampah'),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () async {
                          final picked = await showAdaptivePicker<HargaEntity>(
                            context: context,
                            builder: (context, presentation) =>
                                PilihJenisSampahPicker(
                              selectedId: selected?.id,
                              presentation: presentation,
                            ),
                          );
                          if (picked == null) return;
                          onChanged({
                            ...itemData,
                            'jenis': picked.name,
                            'jenis_sampah_id': picked.id,
                            'harga': hargaFor?.call(picked) ?? picked.price,
                          });
                        },
                        child: Row(
                          children: [
                            if (selected == null) ...[
                              const Icon(Icons.recycling,
                                  color: AppColors.greenDark, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pilih Jenis',
                                  style: AppTextStyle.small
                                      .copyWith(color: AppColors.grey100),
                                ),
                              ),
                            ] else ...[
                              Icon(selected.icon,
                                  color: selected.iconColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selected.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.small.copyWith(
                                    color: AppColors.black,
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            const Icon(Icons.keyboard_arrow_down,
                                color: AppColors.grey200),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: errorLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.close, color: errorColor, size: 20),
                ),
              ),
            ],
          ),
          if (hasError && errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: AppTextStyle.small
                  .copyWith(color: errorColor, fontSize: AppFontSize.sm),
            ),
          ],
          const SizedBox(height: 16),

          // Row 2: Harga
          Row(
            children: [
              Text(
                'Harga/kg:',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Text(
                        'Rp',
                        style: AppTextStyle.small
                            .copyWith(color: AppColors.grey100),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(harga),
                        initialValue: harga > 0
                            ? CurrencyFormatter.formatRupiah(harga)
                                .replaceAll('Rp ', '')
                            : '',
                        readOnly: true,
                        // readOnly sendiri masih menerima fokus, sehingga Tab
                        // berhenti pada kolom yang tidak bisa diketik. Harga
                        // datang dari master jenis sampah, bukan dari
                        // pengelola, jadi ia tidak punya urusan dengan papan
                        // tik sama sekali.
                        canRequestFocus: false,
                        decoration: appBorderlessInputDecoration(),
                        style: AppTextStyle.small.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/kg',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Berat & Subtotal
          Row(
            children: [
              // Berat Input
              Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextFormField(
                  // Seed the field with the same comma-formatted weight shown
                  // everywhere else; onChanged normalises the comma back to a
                  // dot before parsing.
                  initialValue: WeightFormatter.formatKg(berat),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  // Accept a dot or a comma decimal separator (Indonesian
                  // keyboards vary), but only one, and only between digits — the
                  // anchored pattern drops any second separator so "2,,3" or
                  // "2.3.4" can never form. onChanged normalises the comma to a
                  // dot before parsing.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                  ],
                  textAlign: TextAlign.center,
                  // Satu baris, jadi Enter tidak punya makna lain di sini dan
                  // bebas dipakai untuk mengirim.
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmitted?.call(),
                  style: AppTextStyle.small.copyWith(
                    color: AppColors.black,
                    fontWeight: AppFontWeight.bold,
                  ),
                  decoration: appBorderlessInputDecoration(),
                  onChanged: (value) {
                    final cleanValue = value.replaceAll(',', '.');
                    final newBerat = num.tryParse(cleanValue) ?? 0.0;
                    onChanged({
                      ...itemData,
                      'berat': newBerat,
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
              const Spacer(),
              // Subtotal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.grey100,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatRupiah(subtotal),
                    style: AppTextStyle.title1.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.lg,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
