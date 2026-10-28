import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/data_table_card.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';

/// Daftar aktivitas untuk layar lebar: satu baris per setoran atau pencairan
/// dengan kolom yang sejajar, seperti tabel nasabah dan harga. Di telepon
/// daftar tetap berupa kartu yang dikelompokkan per hari.
///
/// Hanya menyajikan baris yang sudah dimuat; memuat berikutnya, kosong, dan
/// gagal ditangani halamannya.
class AktivitasTable extends StatelessWidget {
  const AktivitasTable({
    super.key,
    required this.items,
    required this.onTap,
    this.onEdit,
    this.footer = const [],
    this.toolbar,
    this.pagination,
    this.page,
  });

  final List<ActivitasEntity> items;
  final ValueChanged<ActivitasEntity> onTap;

  /// Dipanggil dari kolom Aksi pada baris setoran. Null menyembunyikan kolom.
  final ValueChanged<ActivitasEntity>? onEdit;

  /// Isi di bawah baris terakhir: indikator muat atau tombol "Muat Lagi".
  final List<Widget> footer;

  /// Baris ringkasan di atas kepala kolom, di dalam kartu.
  final Widget? toolbar;

  /// Paginasi di dasar kartu.
  final Widget? pagination;

  /// Halaman yang tampil; berubahnya mengembalikan gulir ke atas.
  final int? page;

  /// Lebar relatif kolom: waktu, nasabah, tipe, rincian, nominal.
  static const _columns = [4, 4, 2, 4, 3, 3];

  static final _headStyle = AppTextStyle.extraSmall.copyWith(
    color: AppColors.grey100,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static Key rowKey(int index) => ValueKey('aktivitas-row-$index');

  @override
  Widget build(BuildContext context) {
    return DataTableCard(
      toolbar: toolbar,
      header: DataTableCard.head([
        _cell(0, Text('WAKTU', style: _headStyle)),
        _cell(1, Text('NASABAH', style: _headStyle)),
        _cell(2, Text('TIPE', style: _headStyle)),
        _cell(3, Text('RINCIAN', style: _headStyle)),
        _cell(
          4,
          Text('NOMINAL', style: _headStyle, textAlign: TextAlign.end),
        ),
        if (onEdit != null) _aksiCell(Text('AKSI', style: _headStyle)),
      ]),
      body: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (footer.isEmpty ? 0 : 1),
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, i) => i == items.length
            ? Column(children: footer)
            : _Row(
                key: rowKey(i),
                item: items[i],
                onTap: () => onTap(items[i]),
                onEdit: onEdit == null ? null : () => onEdit!(items[i]),
              ),
      ),
      footer: pagination,
      pageKey: page,
    );
  }

  /// Kolom Aksi dimulai agak jauh dari Nominal agar tombolnya tidak mepet.
  static Widget _aksiCell(Widget child) => _cell(
        5,
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xl),
          child: child,
        ),
      );

  static Widget _cell(int i, Widget child) => Expanded(
        flex: _columns[i],
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: child,
        ),
      );
}

class _Row extends StatefulWidget {
  const _Row({
    super.key,
    required this.item,
    required this.onTap,
    this.onEdit,
  });

  final ActivitasEntity item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  ActivitasEntity get item => widget.item;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyle.small.copyWith(color: AppColors.black);
    final muted = base.copyWith(color: AppColors.grey100);
    final waktu = item.trailingCaptions;
    return Semantics(
      button: true,
      // Every row opens a detail, so it gets the hover of the nasabah and
      // harga tables.
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            color: _hover ? AppColors.greenLight.withValues(alpha: 0.45) : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(children: [
              AktivitasTable._cell(
                0,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 2,
                  children: [
                    if (waktu.isNotEmpty) Text(waktu.first, style: base),
                    if (waktu.length > 1) Text(waktu[1], style: muted),
                  ],
                ),
              ),
              AktivitasTable._cell(
                1,
                Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: item.avatarColor,
                    child: Text(
                      item.avatarText,
                      style: AppTextStyle.extraSmall.copyWith(
                        color: item.avatarTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: base.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
              AktivitasTable._cell(
                2,
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomStatusBadge(
                    statusText: item.tipe == ActivitasTipe.setoran
                        ? 'Setoran'
                        : 'Pencairan',
                    backgroundColor: item.tipe == ActivitasTipe.setoran
                        ? AppColors.greenLight
                        : AppColors.warningLight,
                    textColor: item.tipe == ActivitasTipe.setoran
                        ? AppColors.greenDark
                        : AppColors.warning,
                  ),
                ),
              ),
              AktivitasTable._cell(
                3,
                Text(
                  item.subtitleLines.join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
              AktivitasTable._cell(
                4,
                Text(
                  item.amount,
                  textAlign: TextAlign.end,
                  style: base.copyWith(
                    color: item.amountColor ?? AppColors.greenDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.onEdit != null)
                AktivitasTable._aksiCell(
                  Align(
                    alignment: Alignment.centerLeft,
                    child: item.tipe == ActivitasTipe.setoran
                        ? AppButton(
                            key: const ValueKey('aktivitas-edit'),
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            variant: AppButtonVariant.outlined,
                            size: AppButtonSize.compact,
                            expand: false,
                            onPressed: widget.onEdit,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
