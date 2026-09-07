import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/edit_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_confirmation_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';

class DetailNasabahBottomSheet extends StatefulWidget {
  final Map<String, dynamic> customerData;
  final NasabahCubit? nasabahCubit;

  const DetailNasabahBottomSheet({
    super.key,
    required this.customerData,
    this.nasabahCubit,
  });

  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color mintTint = Color(0xFFF0FDF4);
  static const Color errorColor = Color(0xFFBA1A1A);

  @override
  State<DetailNasabahBottomSheet> createState() =>
      _DetailNasabahBottomSheetState();
}

class _DetailNasabahBottomSheetState extends State<DetailNasabahBottomSheet> {
  Future<NasabahRingkasan?>? _ringkasanFuture;

  @override
  void initState() {
    super.initState();
    final id = widget.customerData['id']?.toString();
    if (id != null && id.isNotEmpty && widget.nasabahCubit != null) {
      _ringkasanFuture = widget.nasabahCubit!.fetchRingkasan(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerData = widget.customerData;
    final bool isActive = customerData['isActive'] ?? true;
    final String initials = customerData['initials'] ?? 'NN';
    final String name = customerData['name'] ?? 'Unknown';
    final String phone = customerData['phone'] ?? '-';
    final String balance = customerData['balance'] ?? 'Rp 0';

    final String idNasabah = customerData['idNasabah'] ?? 'NAS-0000';
    final String jenisKelamin = customerData['jenisKelamin'] ?? '-';
    final String tanggalLahir = customerData['tanggalLahir'] ?? '-';
    final String address = customerData['address'] ?? '-';
    final String tanggalDaftar =
        (customerData['tanggalDaftar'] as String?)?.isNotEmpty == true
            ? customerData['tanggalDaftar']
            : '-';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header Section
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isActive
                          ? DetailNasabahBottomSheet.mintTint
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: AppTextStyle.headline1.copyWith(
                        color: isActive
                            ? DetailNasabahBottomSheet.emeraldPrimary
                            : Colors.red[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
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
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              idNasabah,
                              style: AppTextStyle.small.copyWith(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomStatusBadge(isActive: isActive),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info Card Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('ID Nasabah', idNasabah, isBold: true),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Jenis Kelamin',
                      jenisKelamin,
                      isBold: true,
                      icon: Icon(
                        jenisKelamin.toLowerCase() == 'perempuan'
                            ? Icons.female
                            : Icons.male,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Tanggal Lahir', tanggalLahir, isBold: true),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nomor WA', phone, isBold: true),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Saldo',
                      balance,
                      isBold: true,
                      valueColor: DetailNasabahBottomSheet.emeraldPrimary,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Tanggal Daftar',
                      tanggalDaftar,
                      isBold: true,
                      icon: Icon(Icons.calendar_month,
                          size: 16, color: Colors.indigo[300]),
                    ),
                    const SizedBox(height: 16),
                    _buildRingkasanRow(),
                    const SizedBox(height: 20),
                    Text(
                      'Alamat',
                      style: AppTextStyle.small.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address,
                      style: AppTextStyle.title1.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => EditNasabahBottomSheet(
                              customerData: customerData),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Data'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            DetailNasabahBottomSheet.emeraldPrimary,
                        side: const BorderSide(
                            color: DetailNasabahBottomSheet.emeraldPrimary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: AppTextStyle.title1.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (widget.nasabahCubit == null) return;

                        showDialog(
                          context: context,
                          builder: (context) => NasabahConfirmationDialog(
                            isActivating: !isActive,
                            customerName: name,
                            customerId: customerData['id'] ?? idNasabah,
                            nasabahCubit: widget.nasabahCubit!,
                          ),
                        );
                      },
                      icon: Icon(
                          isActive ? Icons.block : Icons.check_circle_outline,
                          size: 18,
                          color: Colors.white),
                      label: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? DetailNasabahBottomSheet.errorColor
                            : DetailNasabahBottomSheet.emeraldPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        textStyle: AppTextStyle.title1.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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

  Widget _buildRingkasanRow() {
    return FutureBuilder<NasabahRingkasan?>(
      future: _ringkasanFuture,
      builder: (context, snapshot) {
        String value;
        if (_ringkasanFuture == null) {
          value = '-';
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          value = 'Memuat...';
        } else if (snapshot.hasData && snapshot.data != null) {
          final r = snapshot.data!;
          value = '${r.jumlahTransaksi} Trx | ${r.totalKg} kg';
        } else {
          value = '-';
        }
        return _buildInfoRow(
          'Ringkasan Trx',
          value,
          isBold: true,
          valueColor: AppColors.statPurple,
          icon: Icon(Icons.bar_chart, size: 16, color: AppColors.statPurple),
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    Widget? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.small.copyWith(
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon,
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyle.title1.copyWith(
                    color: valueColor ?? Colors.black87,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
