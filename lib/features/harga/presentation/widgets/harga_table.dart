import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/data_table_card.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

/// Daftar jenis sampah untuk layar lebar: satu baris per jenis dengan kolom
/// yang sejajar, seperti tabel nasabah. Di telepon daftar tetap berupa kartu.
///
/// Hanya menyajikan; memuat, kosong, dan gagal ditangani halamannya. Mengetuk
/// baris memberi tahu [onTap], dan [selectedId] menandai baris yang sedang
/// terbuka.
class HargaTable extends StatelessWidget {
  const HargaTable({
    super.key,
    required this.items,
    required this.onTap,
    this.selectedId,
    this.footer,
    this.page,
  });

  final List<HargaEntity> items;
  final ValueChanged<HargaEntity> onTap;
  final String? selectedId;

  /// Paginasi di dasar kartu.
  final Widget? footer;

  /// Halaman yang tampil; berubahnya mengembalikan gulir ke atas.
  final int? page;

  /// Kunci baris untuk [id], agar test dapat menemukannya.
  static Key rowKey(String id) => ValueKey('harga-row-$id');

  /// Lebar relatif kolom: jenis, kategori, harga, status.
  static const _columns = [5, 2, 3, 2];

  static final _headStyle = AppTextStyle.extraSmall.copyWith(
    color: AppColors.grey100,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  @override
  Widget build(BuildContext context) {
    return DataTableCard(
      header: DataTableCard.head([
        _cell(0, Text('JENIS SAMPAH', style: _headStyle)),
        _cell(1, Text('KATEGORI', style: _headStyle)),
        _cell(
          2,
          Text('HARGA BELI / KG', style: _headStyle, textAlign: TextAlign.end),
        ),
        _cell(3, Text('STATUS', style: _headStyle), padLeft: true),
      ]),
      body: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) => _Row(
          item: items[index],
          selected: items[index].id == selectedId,
          onTap: () => onTap(items[index]),
        ),
      ),
      footer: footer,
      pageKey: page,
    );
  }

  static Widget _cell(int i, Widget child, {bool padLeft = false}) => Expanded(
        flex: _columns[i],
        child: Padding(
          padding: EdgeInsets.only(left: padLeft ? AppSpacing.xl : 0),
          child: child,
        ),
      );
}

class _Row extends StatefulWidget {
  const _Row({required this.item, required this.selected, required this.onTap});

  final HargaEntity item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final terjadwal = item.hargaTerjadwal;
    final base = AppTextStyle.small.copyWith(color: AppColors.black);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        selected: widget.selected,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            key: HargaTable.rowKey(item.id),
            color: widget.selected
                ? AppColors.greenLight
                : _hover
                    ? AppColors.greenLight.withValues(alpha: 0.45)
                    : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(children: [
              HargaTable._cell(
                0,
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.fill,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(item.icon, color: AppColors.inkSoft, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: base.copyWith(fontWeight: FontWeight.w600)),
                        Text(item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: base.copyWith(color: AppColors.grey100)),
                      ],
                    ),
                  ),
                ]),
              ),
              HargaTable._cell(
                1,
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomStatusBadge(statusText: item.badgeText),
                ),
              ),
              HargaTable._cell(
                2,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(item.priceFormatted,
                        style: base.copyWith(fontWeight: FontWeight.w600)),
                    if (terjadwal != null)
                      Text(
                        '${CurrencyFormatter.formatRupiah(terjadwal.harga)} mulai '
                        '${formatTanggalId(terjadwal.berlakuMulai.toLocal())}',
                        textAlign: TextAlign.end,
                        style: AppTextStyle.extraSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              HargaTable._cell(
                3,
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomStatusBadge(isActive: item.isActive),
                ),
                padLeft: true,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
