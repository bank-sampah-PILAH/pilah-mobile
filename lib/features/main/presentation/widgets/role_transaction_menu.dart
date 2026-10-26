import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

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
  static const setoranKey = ValueKey('transaction-menu-setoran');
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
      return SizedBox(
        width: 48,
        height: 48,
        child: PopupMenuButton<_TransactionAction>(
          key: menuKey,
          tooltip: 'Transaksi',
          icon: Icon(Icons.receipt_long_outlined, color: selectionColor),
          itemBuilder: (context) => [
            PopupMenuItem(
              key: setoranKey,
              value: _TransactionAction.setoran,
              child: _PopupMenuLabel(
                icon: Icons.add_circle_outline,
                label: 'Setoran',
                selected: selected,
              ),
            ),
            const PopupMenuItem(
              key: pencairanKey,
              enabled: false,
              child: _PopupMenuLabel(
                icon: Icons.payments_outlined,
                label: 'Pencairan',
                enabled: false,
              ),
            ),
          ],
          onSelected: (_) => _openSetoran(),
        ),
      );
    }

    final groupColor =
        selected || riwayatSelected ? AppColors.greenDark : AppColors.inkSoft;
    final riwayatColor =
        riwayatSelected ? AppColors.greenDark : AppColors.inkSoft;
    return ExpansionTile(
      key: menuKey,
      initiallyExpanded: true,
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: groupColor,
      collapsedIconColor: groupColor,
      textColor: groupColor,
      collapsedTextColor: groupColor,
      leading: Icon(Icons.receipt_long_outlined, color: groupColor),
      title: Text(
        'Transaksi',
        style: AppTextStyle.small.copyWith(
          color: groupColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      childrenPadding: const EdgeInsets.only(left: AppSpacing.xl),
      children: [
        ListTile(
          key: setoranKey,
          dense: true,
          selected: selected,
          selectedColor: selectionColor,
          selectedTileColor: Colors.transparent,
          leading: Icon(Icons.add_circle_outline, color: selectionColor),
          title: Text(
            'Setoran',
            style: AppTextStyle.small.copyWith(color: selectionColor),
          ),
          onTap: _openSetoran,
        ),
        ListTile(
          key: pencairanKey,
          dense: true,
          enabled: false,
          leading: const Icon(Icons.payments_outlined),
          title: Text(
            'Pencairan',
            style: AppTextStyle.small.copyWith(color: AppColors.grey100),
          ),
        ),
        if (onRiwayat != null)
          ListTile(
            key: riwayatKey,
            dense: true,
            selected: riwayatSelected,
            selectedColor: riwayatColor,
            selectedTileColor: Colors.transparent,
            leading: Icon(Icons.history, color: riwayatColor),
            title: Text(
              'Riwayat',
              style: AppTextStyle.small.copyWith(color: riwayatColor),
            ),
            onTap: _openRiwayat,
          ),
      ],
    );
  }
}

enum _TransactionAction { setoran }

class _PopupMenuLabel extends StatelessWidget {
  const _PopupMenuLabel({
    required this.icon,
    required this.label,
    this.enabled = true,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.grey100
        : selected
            ? AppColors.greenDark
            : AppColors.inkSoft;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: AppTextStyle.small.copyWith(color: color),
        ),
      ],
    );
  }
}
