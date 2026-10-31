import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/data_table_card.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_setoran_detail.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

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
    this.loadSetoranDetail,
    this.footer = const [],
    this.toolbar,
    this.pagination,
    this.page,
  });

  final List<ActivitasEntity> items;
  final ValueChanged<ActivitasEntity> onTap;

  /// Dipanggil dari kolom Aksi pada baris setoran. Null menyembunyikan kolom.
  final ValueChanged<ActivitasEntity>? onEdit;

  /// Memuat rincian transaksi saat baris setoran dibuka.
  final Future<TransaksiDetailEntity?> Function(String id)? loadSetoranDetail;

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
    fontWeight: AppFontWeight.semibold,
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
                loadSetoranDetail: loadSetoranDetail,
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
    this.loadSetoranDetail,
  });

  final ActivitasEntity item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final Future<TransaksiDetailEntity?> Function(String id)? loadSetoranDetail;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;
  bool _expanded = false;

  ActivitasEntity get item => widget.item;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyle.small.copyWith(color: AppColors.black);
    final muted = base.copyWith(color: AppColors.grey100);
    final waktu = item.trailingCaptions;
    final expandable = item.tipe == ActivitasTipe.setoran;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        color: _hover ? AppColors.greenLight.withValues(alpha: 0.45) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              expanded: expandable && _expanded,
              hint: expandable
                  ? _expanded
                      ? 'Ketuk untuk menutup rincian'
                      : 'Ketuk untuk melihat rincian'
                  : null,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () {
                    if (expandable) {
                      setState(() => _expanded = !_expanded);
                    } else {
                      widget.onTap();
                    }
                  },
                  child: Padding(
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
                            if (waktu.isNotEmpty)
                              Text(waktu.first, style: base),
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
                                fontWeight: AppFontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: base.copyWith(
                                  fontWeight: AppFontWeight.semibold),
                            ),
                          ),
                        ]),
                      ),
                      AktivitasTable._cell(
                        2,
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CustomStatusBadge(
                            statusText: expandable ? 'Setoran' : 'Pencairan',
                            backgroundColor: expandable
                                ? AppColors.greenLight
                                : AppColors.warningLight,
                            textColor: expandable
                                ? AppColors.greenDark
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      AktivitasTable._cell(
                        3,
                        Row(children: [
                          Expanded(
                            child: Text(
                              item.subtitleLines.join(' • '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: muted,
                            ),
                          ),
                          if (expandable) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              color: AppColors.grey100,
                              size: 18,
                            ),
                          ],
                        ]),
                      ),
                      AktivitasTable._cell(
                        4,
                        Text(
                          item.amount,
                          textAlign: TextAlign.end,
                          style: base.copyWith(
                            color: item.amountColor ?? AppColors.greenDark,
                            fontWeight: AppFontWeight.semibold,
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
            ),
            if (expandable)
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? AktivitasSetoranDetail(
                        key: ValueKey(
                            'setoran-details-${item.transaksi?.id ?? ''}'),
                        transactionId: item.transaksi?.id ?? '',
                        loadDetail:
                            widget.loadSetoranDetail ?? (_) async => null,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
