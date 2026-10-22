import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Pengurus-only transaction actions shown before the normal destinations.
class RoleTransactionMenu extends StatelessWidget {
  const RoleTransactionMenu({
    super.key,
    required this.onSetoran,
    this.onClose,
    this.compact = false,
  });

  static const menuKey = ValueKey('transaction-menu');
  static const setoranKey = ValueKey('transaction-menu-setoran');
  static const pencairanKey = ValueKey('transaction-menu-pencairan');

  final VoidCallback onSetoran;
  final VoidCallback? onClose;
  final bool compact;

  void _openSetoran() {
    onClose?.call();
    onSetoran();
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SizedBox(
        width: 48,
        height: 48,
        child: PopupMenuButton<_TransactionAction>(
          key: menuKey,
          tooltip: 'Transaksi',
          icon: const Icon(Icons.receipt_long_outlined),
          itemBuilder: (context) => [
            const PopupMenuItem(
              key: setoranKey,
              value: _TransactionAction.setoran,
              child: _PopupMenuLabel(
                icon: Icons.add_circle_outline,
                label: 'Setoran',
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

    return ExpansionTile(
      key: menuKey,
      initiallyExpanded: true,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.receipt_long_outlined),
      title: Text(
        'Transaksi',
        style: AppTextStyle.small.copyWith(
          color: AppColors.inkSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      childrenPadding: const EdgeInsets.only(left: AppSpacing.xl),
      children: [
        ListTile(
          key: setoranKey,
          dense: true,
          leading: const Icon(Icons.add_circle_outline),
          title: Text(
            'Setoran',
            style: AppTextStyle.small.copyWith(color: AppColors.inkSoft),
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
  });

  final IconData icon;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: enabled ? AppColors.inkSoft : AppColors.grey100),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTextStyle.small.copyWith(
              color: enabled ? AppColors.inkSoft : AppColors.grey100,
            ),
          ),
        ],
      );
}
