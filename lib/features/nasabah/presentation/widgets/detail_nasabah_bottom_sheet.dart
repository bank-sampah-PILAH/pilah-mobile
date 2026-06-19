import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/edit_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_confirmation_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_outlined_button.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';

class DetailNasabahBottomSheet extends StatelessWidget {
  final Map<String, dynamic> customerData;
  final NasabahCubit? nasabahCubit;

  const DetailNasabahBottomSheet({
    super.key,
    required this.customerData,
    this.nasabahCubit,
  });

  // Emerald Eco System Tokens
  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color mintTint = Color(0xFFF0FDF4);
  static const Color errorColor = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    final bool isActive = customerData['isActive'] ?? true;
    final String initials = customerData['initials'] ?? 'NN';
    final String name = customerData['name'] ?? 'Unknown';
    final String phone = customerData['phone'] ?? '-';
    final String balance = customerData['balance'] ?? 'Rp 0';
    
    // Derived or mocked data
    final String customerId = customerData['id'] ?? 'NAS-0891';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSheetHeader(title: ''),

              // Header Row
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isActive ? mintTint : Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: AppTextStyle.headline1.copyWith(
                        color: isActive ? emeraldPrimary : Colors.red[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyle.headline1.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              customerId,
                              style: AppTextStyle.small.copyWith(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomStatusBadge(
                              isActive: isActive,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                decoration: BoxDecoration(
                  color: mintTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Nomor WA', phone),
                    const Divider(color: Colors.white, height: 24, thickness: 1.5),
                    _buildInfoRow('Saldo', balance, valueColor: emeraldPrimary),
                    const Divider(color: Colors.white, height: 24, thickness: 1.5),
                    _buildInfoRow('Tanggal Daftar', '📅 12 Mei 2026'),
                    const Divider(color: Colors.white, height: 24, thickness: 1.5),
                    _buildInfoRow('Ringkasan Trx', '📊 Total: 15 Trx | 120 kg', valueColor: const Color(0xFF7C3AED)),
                    const Divider(color: Colors.white, height: 24, thickness: 1.5),
                    _buildInfoRow('Alamat', 'Jl. Mawar No.12, RT.02/03, Kukusan', multiline: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: CustomOutlinedButton(
                      title: 'Edit Data',
                      borderColor: emeraldPrimary,
                      textColor: emeraldPrimary,
                      onPressed: isActive ? () {
                        context.pop();
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true, 
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => EditNasabahBottomSheet(customerData: customerData),
                        );
                      } : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomPrimaryButton(
                      title: isActive ? 'Nonaktifkan' : 'Aktifkan',
                      color: isActive ? errorColor : emeraldPrimary,
                      icon: isActive ? Icons.block : Icons.check,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => NasabahConfirmationDialog(
                            isActivating: !isActive,
                            customerName: name,
                            customerId: customerId,
                            nasabahCubit: nasabahCubit!,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool multiline = false}) {
    return Row(
      crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyle.small.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyle.small.copyWith(
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
