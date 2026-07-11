import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';

class DetailTransaksiBottomSheet extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const DetailTransaksiBottomSheet({
    super.key,
    required this.transactionData,
  });

  @override
  State<DetailTransaksiBottomSheet> createState() => _DetailTransaksiBottomSheetState();
}

class _DetailTransaksiBottomSheetState extends State<DetailTransaksiBottomSheet> {
  // Emerald Eco System Tokens
  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color mintTint = Color(0xFFF0FDF4); // or #ecfdf5 as requested
  static const Color errorColor = Color(0xFFDC2626); // red for failed WA

  String currentWaStatus = '';
  bool isLoadingWa = false;

  @override
  void initState() {
    super.initState();
    currentWaStatus = widget.transactionData['waStatus'] ?? 'sent';
  }

  Future<void> _retryWaNotification() async {
    setState(() {
      isLoadingWa = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        isLoadingWa = false;
        currentWaStatus = 'sent';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String initials = widget.transactionData['initials'] ?? 'NN';
    final Color avatarColor = widget.transactionData['avatarColor'] ?? Colors.grey[200]!;
    final Color textColor = widget.transactionData['textColor'] ?? Colors.grey[600]!;
    final String name = widget.transactionData['name'] ?? 'Unknown';
    final String time = widget.transactionData['time'] ?? 'Hari ini';
    final String amount = widget.transactionData['amount'] ?? 'Rp 0';
    final String balance = widget.transactionData['balance'] ?? 'Rp 141.100'; // Default fallback
    final List<Map<String, dynamic>> items = widget.transactionData['items'] ?? [];

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

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Transaksi',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  CustomStatusBadge(
                    statusText: 'Selesai',
                    backgroundColor: mintTint,
                    textColor: emeraldPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Customer Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // surface-container-low
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        borderRadius: BorderRadius.circular(12),
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
                          Text(
                            name,
                            style: AppTextStyle.title1.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            time,
                            style: AppTextStyle.small.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rincian Setoran Section
              Text(
                'RINCIAN SETORAN',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'JENIS',
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'BERAT',
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'HARGA/KG',
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'SUBTOTAL',
                            textAlign: TextAlign.right,
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 12),
                    
                    // Table Items
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['jenis'] ?? '',
                              style: AppTextStyle.small.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['berat'] ?? '',
                              style: AppTextStyle.small.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['harga'] ?? '',
                              style: AppTextStyle.small.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['subtotal'] ?? '',
                              textAlign: TextAlign.right,
                              style: AppTextStyle.small.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                    // Total Row
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Setoran',
                          style: AppTextStyle.small.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          amount,
                          style: AppTextStyle.title1.copyWith(
                            color: emeraldPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Saldo Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mintTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Setelah Transaksi',
                          style: AppTextStyle.small.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          balance,
                          style: AppTextStyle.headline1.copyWith(
                            color: emeraldPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status Notifikasi WA
              Text(
                'STATUS NOTIFIKASI WA',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildWaStatusBox(currentWaStatus, name),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaStatusBox(String status, String name) {
    if (status == 'sent') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: emeraldPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mintTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wechat, color: emeraldPrimary, size: 24), // Placeholder for WA icon
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terkirim Sukses',
                    style: AppTextStyle.small.copyWith(
                      color: emeraldPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ke $name',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check, color: emeraldPrimary, size: 20),
          ],
        ),
      );
    } else {
      // Failed Status
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: errorColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2), // very light red
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wechat, color: errorColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gagal Kirim',
                    style: AppTextStyle.small.copyWith(
                      color: errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ke $name',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            isLoadingWa
                ? Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: emeraldPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : SizedBox(
                    width: 120, // To constraint the CustomPrimaryButton if needed, or simply use it natively
                    child: CustomPrimaryButton(
                      title: 'Coba Lagi',
                      icon: Icons.refresh,
                      onPressed: _retryWaNotification,
                    ),
                  ),
          ],
        ),
      );
    }
  }
}
