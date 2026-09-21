import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_approval_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';

class NasabahListItem extends StatelessWidget {
  final bool isActive;
  final String initials;
  final Color avatarColor;
  final Color textColor;
  final String name;
  final String phone;
  final String balance;
  final String? id;
  final String? idNasabah;
  final String? jenisKelamin;
  final String? tanggalLahir;
  final String? tanggalDaftar;
  final String? address;

  /// Pending membership submission (PIL-188): renders a Menunggu badge and
  /// Setujui/Tolak actions instead of the detail toggle flow.
  final bool isPending;
  final NasabahCubit? nasabahCubit;

  const NasabahListItem({
    super.key,
    required this.isActive,
    required this.initials,
    required this.avatarColor,
    required this.textColor,
    required this.name,
    required this.phone,
    required this.balance,
    this.id,
    this.idNasabah,
    this.jenisKelamin,
    this.tanggalLahir,
    this.tanggalDaftar,
    this.address,
    this.isPending = false,
    this.nasabahCubit,
  });

  void _onTap(BuildContext context) {
    if (isPending) {
      _showDecisionDialog(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailNasabahBottomSheet(
        customerData: {
          'id': id,
          'isActive': isActive,
          'initials': initials,
          'name': name,
          'phone': phone,
          'balance': balance,
          'idNasabah': idNasabah,
          'jenisKelamin': jenisKelamin,
          'tanggalLahir': tanggalLahir,
          'tanggalDaftar': tanggalDaftar,
          'address': address,
        },
        nasabahCubit: nasabahCubit,
      ),
    );
  }

  /// Approve/reject flow for pending submissions (PIL-188). Captured before
  /// any await so notifications survive the list reload rebuilding this item.
  Future<void> _showDecisionDialog(BuildContext context) async {
    final cubit = nasabahCubit;
    if (cubit == null) return;
    final overlayContext = Navigator.of(context, rootNavigator: true).context;

    final reject = await _showActionSheet(context);
    if (reject == null || !context.mounted) return;
    final catatan = await showNasabahApprovalDialog(
      context,
      isApproving: !reject,
      customerName: name,
    );
    if (catatan == null) return;
    final error = await cubit.decideNasabah(
      id ?? idNasabah ?? '',
      approve: !reject,
      catatan: catatan,
    );
    if (overlayContext.mounted && error != null) {
      AppNotification.showError(
        overlayContext,
        title: 'Gagal',
        message: error.displayMessage,
      );
    }
  }

  /// Action sheet for a pending submission: Setujui / Tolak. Returns `true`
  /// to reject, `false` to approve, `null` when dismissed.
  Future<bool?> _showActionSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF006D44),
                ),
                title: const Text('Setujui'),
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text('Tolak'),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTextStyle.title1.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppTextStyle.title1.copyWith(
                            color: isActive ? Colors.black87 : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(width: 8),
                        _PendingBadge(),
                      ] else if (!isActive) ...[
                        const SizedBox(width: 8),
                        CustomStatusBadge(isActive: false),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: AppTextStyle.small.copyWith(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  balance,
                  style: AppTextStyle.title1.copyWith(
                    color: isActive ? AppColors.greenDark : Colors.grey[500],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'saldo',
                  style: AppTextStyle.extraSmall.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Menunggu',
        style: AppTextStyle.extraSmall.copyWith(
          color: const Color(0xFFB26A00),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
