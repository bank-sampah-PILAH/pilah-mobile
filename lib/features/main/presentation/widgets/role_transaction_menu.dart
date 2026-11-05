import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// Pengurus-only transaction actions shown before the normal destinations.
class RoleTransactionMenu extends StatelessWidget {
  const RoleTransactionMenu({
    super.key,
    required this.onSetoran,
    this.onRiwayat,
    this.onClose,
    this.compact = false,
    this.selected = false,
    this.riwayatSelected = false,
  });

  static const menuKey = ValueKey('transaction-menu');
  static const headerKey = ValueKey('transaction-menu-header');
  static const setoranKey = ValueKey('transaction-menu-setoran');

  /// Pencairan tidak lagi digambar (PIL-434). Kuncinya tetap ada supaya
  /// pengujian bisa menyatakan ketidakhadirannya, dan supaya baris itu kembali
  /// dengan kunci yang sama ketika fiturnya dibuka lagi.
  static const pencairanKey = ValueKey('transaction-menu-pencairan');
  static const riwayatKey = ValueKey('transaction-menu-riwayat');

  final VoidCallback onSetoran;

  /// Membuka riwayat transaksi. Null berarti Riwayat tidak ada di menu ini;
  /// menu ringkas tidak pernah menampilkannya.
  final VoidCallback? onRiwayat;
  final VoidCallback? onClose;
  final bool compact;
  final bool selected;
  final bool riwayatSelected;

  void _openSetoran() {
    onClose?.call();
    onSetoran();
  }

  void _openRiwayat() {
    onClose?.call();
    onRiwayat!();
  }

  @override
  Widget build(BuildContext context) {
    final selectionColor = selected ? AppColors.greenDark : AppColors.inkSoft;
    if (compact) {
      // Setoran adalah satu-satunya transaksi yang terbuka (PIL-434), dan
      // menu dengan satu isi menghabiskan satu ketukan untuk pilihan yang
      // bukan pilihan. Jadi ikonnya langsung membuka Setoran. Ikon dan
      // keadaan terpilihnya tetap milik kelompok Transaksi, karena itulah
      // yang diwakili slot ini pada rail.
      //
      // Tooltipnya menyebut keduanya: ikon tanpa label pada rail ringkas
      // hanya dinamai oleh tooltip itu, jadi menyebut *Setoran* saja membuat
      // kelompok Transaksi tak bisa ditemukan oleh pembaca layar yang
      // mencarinya seperti pada rail lebar, sementara menyebut *Transaksi*
      // saja menjanjikan pilihan yang tidak akan muncul.
      //
      // Membuka kembali Pencairan menuntut slot ini digarap sendiri — menu
      // pilihannya dulu di sini sudah dihapus, jadi tanpa itu rail lebar dan
      // drawer menampilkan barisnya sementara rail ringkas tetap langsung ke
      // Setoran.
      return SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          key: menuKey,
          tooltip: 'Transaksi: Setoran',
          icon: Icon(Icons.receipt_long_outlined, color: selectionColor),
          onPressed: _openSetoran,
        ),
      );
    }

    return _TransactionAccordion(
      key: menuKey,
      onSetoran: _openSetoran,
      onRiwayat: onRiwayat == null ? null : _openRiwayat,
      selected: selected,
      riwayatSelected: riwayatSelected,
    );
  }
}

/// Akordeon Transaksi pada rail lebar dan drawer.
///
/// Baris-barisnya digambar seperti destinasi lain pada rail: ikon di dalam
/// pil bulat 56x32 yang terisi hijau muda saat dipilih dan separuhnya saat
/// kursor di atasnya, lalu label di sebelahnya. Anak-anaknya memakai baris
/// yang sama, hanya menjorok ke dalam.
class _TransactionAccordion extends StatefulWidget {
  const _TransactionAccordion({
    super.key,
    required this.onSetoran,
    required this.onRiwayat,
    required this.selected,
    required this.riwayatSelected,
  });

  final VoidCallback onSetoran;
  final VoidCallback? onRiwayat;
  final bool selected;
  final bool riwayatSelected;

  @override
  State<_TransactionAccordion> createState() => _TransactionAccordionState();
}

class _TransactionAccordionState extends State<_TransactionAccordion> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final groupSelected = widget.selected || widget.riwayatSelected;
    final groupColor = groupSelected ? AppColors.greenDark : AppColors.inkSoft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoleMenuRow(
          key: RoleTransactionMenu.headerKey,
          icon: Icons.receipt_long_outlined,
          label: 'Transaksi',
          selected: groupSelected,
          expanded: _expanded,
          onTap: () => setState(() => _expanded = !_expanded),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: groupColor,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.onRiwayat != null)
                        RoleMenuRow(
                          key: RoleTransactionMenu.riwayatKey,
                          icon: Icons.history,
                          label: 'Riwayat',
                          selected: widget.riwayatSelected,
                          onTap: widget.onRiwayat,
                        ),
                      RoleMenuRow(
                        key: RoleTransactionMenu.setoranKey,
                        icon: Icons.add_circle_outline,
                        label: 'Setoran',
                        selected: widget.selected,
                        onTap: widget.onSetoran,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Satu baris menu bergaya destinasi rail. Tanpa [onTap] baris itu nonaktif.
class RoleMenuRow extends StatefulWidget {
  const RoleMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
    this.expanded,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  /// Hanya untuk baris yang membuka dan menutup daftar; null untuk baris lain.
  final bool? expanded;
  final Widget? trailing;

  bool get enabled => onTap != null;

  @override
  State<RoleMenuRow> createState() => _RoleMenuRowState();
}

class _RoleMenuRowState extends State<RoleMenuRow> {
  /// Tinggi baris (target sentuh minimal, DESIGN.md) dan ukuran pil rail.
  static const double _rowHeight = kMinInteractiveDimension;
  static const double _pillWidth = 56;
  static const double _pillHeight = 32;

  Color get _activeColor =>
      widget.selected ? AppColors.greenDark : AppColors.inkSoft;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.enabled;
    // Warna nonaktif sama dengan destinasi rail yang nonaktif.
    final disabled = scheme.onSurface.withValues(alpha: 0.38);
    final color = enabled ? _activeColor : disabled;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      expanded: widget.expanded,
      label: widget.label,
      excludeSemantics: true,
      child: _PillInkResponse(
        onTap: widget.onTap,
        // Sama dengan rail: primer 12% saat ditekan dan 4% saat kursor lewat,
        // digambar hanya di dalam pil, bukan di seluruh baris.
        splashColor: scheme.primary.withValues(alpha: 0.12),
        hoverColor: scheme.primary.withValues(alpha: 0.04),
        pill: const Rect.fromLTWH(
          0,
          (_rowHeight - _pillHeight) / 2,
          _pillWidth,
          _pillHeight,
        ),
        child: SizedBox(
          height: _rowHeight,
          child: Row(
            children: [
              Container(
                width: _pillWidth,
                height: _pillHeight,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: widget.selected
                      ? AppColors.greenLight
                      : Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: Icon(widget.icon, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTextStyle.small.copyWith(
                    color: color,
                    fontWeight: widget.selected
                        ? AppFontWeight.semibold
                        : AppFontWeight.medium,
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Ink yang seluruh barisnya bisa disentuh tetapi hanya menggambar sorot dan
/// riak di dalam [pill], seperti `_IndicatorInkWell` pada NavigationRail.
class _PillInkResponse extends InkResponse {
  const _PillInkResponse({
    super.child,
    super.onTap,
    super.splashColor,
    super.hoverColor,
    required this.pill,
  }) : super(
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          customBorder: const StadiumBorder(),
        );

  final Rect pill;

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) => () => pill;
}
