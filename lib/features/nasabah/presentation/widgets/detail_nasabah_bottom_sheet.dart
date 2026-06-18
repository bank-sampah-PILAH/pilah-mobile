import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class DetailNasabahBottomSheet extends StatelessWidget {
  const DetailNasabahBottomSheet({super.key});

  // Emerald Eco System Tokens
  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color mintTint = Color(0xFFF0FDF4);
  static const Color errorColor = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
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
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Header Row
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: mintTint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'AR',
                      style: AppTextStyle.headline1.copyWith(
                        color: emeraldPrimary,
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
                          'Ahmad Ridwan',
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
                              'NAS-0891',
                              style: AppTextStyle.small.copyWith(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: mintTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Aktif',
                                style: AppTextStyle.extraSmall.copyWith(
                                  color: emeraldPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                    _buildInfoRow('Nomor WA', '0812-3456-7890'),
                    const Divider(color: Colors.white, height: 24, thickness: 1.5),
                    _buildInfoRow('Saldo', 'Rp 450.000', valueColor: emeraldPrimary),
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
                    child: OutlinedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.edit_outlined, color: emeraldPrimary, size: 18),
                      label: Text(
                        'Edit Data',
                        style: AppTextStyle.title1.copyWith(
                          color: emeraldPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: emeraldPrimary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.block, color: Colors.white, size: 18),
                      label: Text(
                        'Nonaktifkan',
                        style: AppTextStyle.title1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
