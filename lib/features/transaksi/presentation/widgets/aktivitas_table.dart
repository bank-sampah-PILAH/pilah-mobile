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
    this.onHapus,
    this.loadSetoranDetail,
    this.footer = const [],
    this.toolbar,
    this.pagination,
    this.page,
    this.selectedIds,
    this.onToggleSelection,
    this.onSelectAll,
  });

  static const selectAllKey = ValueKey('aktivitas-select-all');

  final List<ActivitasEntity> items;

  /// Non-null shows the checkbox column (always visible on wide screens); an
  /// empty set means nothing is checked yet.
  final Set<String>? selectedIds;
  final ValueChanged<String>? onToggleSelection;

  /// Replaces the selection with these ids; an empty list clears it.
  final ValueChanged<Iterable<String>>? onSelectAll;
  final ValueChanged<ActivitasEntity> onTap;

  /// Dipanggil dari kolom Aksi pada baris setoran. Null menyembunyikan kolom.
  final ValueChanged<ActivitasEntity>? onEdit;

  /// Tombol Hapus di kolom Aksi, di samping Edit (PIL-428).
  final ValueChanged<ActivitasEntity>? onHapus;

  /// Fetches full details when a setoran row is expanded.
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

  static Key rowKey(ActivitasEntity item) {
    final id = item.transaksi?.id ?? item.pencairan?.id;
    return id == null || id.isEmpty
        ? ObjectKey(item)
        : ValueKey('aktivitas-row-${item.tipe.name}-$id');
  }

  @override
  Widget build(BuildContext context) {
    return DataTableCard(
      toolbar: toolbar,
      header: DataTableCard.head([
        if (selectedIds != null) SizedBox(width: 48, child: _selectAllBox()),
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
                key: rowKey(items[i]),
                item: items[i],
                onTap: () => onTap(items[i]),
                onEdit: onEdit == null ? null : () => onEdit!(items[i]),
                onHapus: onHapus == null ? null : () => onHapus!(items[i]),
                loadSetoranDetail: loadSetoranDetail,
                selectedIds: selectedIds,
                onToggleSelection: onToggleSelection,
              ),
      ),
      footer: pagination,
      pageKey: page,
    );
  }

  /// Selects every selectable setoran on this page, or clears when all are.
  Widget _selectAllBox() {
    final ids = [
      for (final item in items)
        if (item.isSelectableSetoran) item.transaksi!.id,
    ];
    final chosen = ids.where(selectedIds!.contains).length;
    final all = ids.isNotEmpty && chosen == ids.length;
    return Checkbox(
      key: selectAllKey,
      tristate: true,
      value: all ? true : (chosen > 0 ? null : false),
      semanticLabel: 'Pilih semua setoran di halaman ini',
      onChanged: ids.isEmpty || onSelectAll == null
          ? null
          : (_) => onSelectAll!(all ? const [] : ids),
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
    this.onHapus,
    this.loadSetoranDetail,
    this.selectedIds,
    this.onToggleSelection,
  });

  final ActivitasEntity item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onHapus;
  final Future<TransaksiDetailEntity?> Function(String id)? loadSetoranDetail;
  final Set<String>? selectedIds;
  final ValueChanged<String>? onToggleSelection;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;
  bool _expanded = false;

  ActivitasEntity get item => widget.item;

  bool get _dibatalkan => item.transaksi?.isDibatalkan ?? false;

  /// Only a setoran still tercatat can be edited or cancelled.
  bool get _bisaDiubah => item.tipe == ActivitasTipe.setoran && !_dibatalkan;
  bool get _selectable => item.isSelectableSetoran;
  bool get _anySelected => widget.selectedIds?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final expandable = item.tipe == ActivitasTipe.setoran;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        color: _hover ? AppColors.greenLight.withValues(alpha: 0.45) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDataRow(context, expandable),
            if (expandable && !_anySelected) _buildExpandedDetail(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, bool expandable) {
    final base = AppTextStyle.small.copyWith(color: AppColors.black);
    return Semantics(
      button: true,
      expanded: expandable && _expanded,
      hint: _hint(expandable),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => _handleTap(expandable),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: _buildCells(
              base,
              base.copyWith(color: AppColors.grey100),
              expandable,
            ),
          ),
        ),
      ),
    );
  }

  String? _hint(bool expandable) {
    if (!expandable) return null;
    return _expanded
        ? 'Ketuk untuk menutup rincian'
        : 'Ketuk untuk melihat rincian';
  }

  void _handleTap(bool expandable) {
    if (_anySelected) {
      if (_selectable) widget.onToggleSelection?.call(item.transaksi!.id);
      return;
    }
    if (expandable) {
      setState(() => _expanded = !_expanded);
    } else {
      widget.onTap();
    }
  }

  Widget _buildCells(TextStyle base, TextStyle muted, bool expandable) {
    final waktu = item.trailingCaptions;
    return Row(
      children: [
        if (widget.selectedIds != null)
          SizedBox(
            width: 48,
            child: _selectable
                ? Checkbox(
                    value: widget.selectedIds!.contains(item.transaksi!.id),
                    semanticLabel: 'Pilih setoran ${item.title}',
                    onChanged: (_) =>
                        widget.onToggleSelection?.call(item.transaksi!.id),
                  )
                : null,
          ),
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
        _nasabahCell(base),
        _typeCell(expandable),
        _detailCell(muted, expandable),
        _amountCell(base),
        if (widget.onEdit != null) _editCell(),
      ],
    );
  }

  Widget _nasabahCell(TextStyle base) => AktivitasTable._cell(
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
              style: base.copyWith(fontWeight: AppFontWeight.semibold),
            ),
          ),
        ]),
      );

  Widget _typeCell(bool expandable) => AktivitasTable._cell(
        2,
        Align(alignment: Alignment.centerLeft, child: _typeBadge(expandable)),
      );

  /// A voided setoran reads Dibatalkan in place of its type (PIL-428).
  Widget _typeBadge(bool expandable) {
    if (_dibatalkan) {
      return const CustomStatusBadge(
        statusText: 'Dibatalkan',
        backgroundColor: AppColors.fill,
        textColor: AppColors.grey100,
      );
    }
    return CustomStatusBadge(
      statusText: expandable ? 'Setoran' : 'Pencairan',
      backgroundColor:
          expandable ? AppColors.greenLight : AppColors.warningLight,
      textColor: expandable ? AppColors.greenDark : AppColors.warning,
    );
  }

  Widget _detailCell(TextStyle muted, bool expandable) => AktivitasTable._cell(
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
      );

  Widget _amountCell(TextStyle base) => AktivitasTable._cell(
        4,
        Text(
          item.amount,
          textAlign: TextAlign.end,
          style: base.copyWith(
            color: item.amountColor ?? AppColors.greenDark,
            fontWeight: AppFontWeight.semibold,
          ),
        ),
      );

  Widget _editCell() => AktivitasTable._aksiCell(
        Align(
          alignment: Alignment.centerLeft,
          child: _bisaDiubah && !_anySelected
              ? Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton(
                      key: const ValueKey('aktivitas-edit'),
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.compact,
                      expand: false,
                      onPressed: widget.onEdit,
                    ),
                    if (widget.onHapus != null)
                      AppButton(
                        key: const ValueKey('aktivitas-hapus'),
                        label: 'Hapus',
                        icon: Icons.delete_outline,
                        variant: AppButtonVariant.destructiveOutlined,
                        size: AppButtonSize.compact,
                        expand: false,
                        onPressed: widget.onHapus,
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      );

  Widget _buildExpandedDetail(BuildContext context) => AnimatedSize(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: _expanded
            ? AktivitasSetoranDetail(
                key: ValueKey('setoran-details-${item.transaksi?.id ?? ''}'),
                transactionId: item.transaksi?.id ?? '',
                loadDetail: widget.loadSetoranDetail ?? (_) async => null,
              )
            : const SizedBox.shrink(),
      );
}
