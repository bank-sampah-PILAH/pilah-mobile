import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class TransaksiBerhasilBottomSheet extends StatelessWidget {
  final String customerName;
  final int totalSetoran;
  final int newBalance;
  final int itemCount;

  const TransaksiBerhasilBottomSheet({
    super.key,
    required this.customerName,
    required this.totalSetoran,
    required this.newBalance,
    required this.itemCount,
  });

  static const Color emeraldPrimary = Color(0xFF006D44);

  String _formatCurrency(int value) {
    String str = value.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: emeraldPrimary, size: 40),
          ),
          const SizedBox(height: 24),

          // Title & Subtitle
          Text(
            'Transaksi Berhasil!',
            style: AppTextStyle.headline1.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$itemCount jenis sampah berhasil dicatat.',
            style: AppTextStyle.small.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),

          // Summary Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Nasabah', customerName, isBold: false),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
                _buildSummaryRow('Nilai Setoran', '+${_formatCurrency(totalSetoran)}', isPrimary: true),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),
                _buildSummaryRow('Saldo Terbaru', _formatCurrency(newBalance), isPrimary: true),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          ElevatedButton(
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop(); // dismiss modal
              router.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: emeraldPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Kirim Notif WhatsApp & Selesai',
              style: AppTextStyle.title1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isPrimary = false, bool isBold = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyle.small.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: AppTextStyle.title1.copyWith(
            color: isPrimary ? emeraldPrimary : Colors.black87,
            fontWeight: isBold || isPrimary ? FontWeight.bold : FontWeight.w600,
            fontSize: isPrimary ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
