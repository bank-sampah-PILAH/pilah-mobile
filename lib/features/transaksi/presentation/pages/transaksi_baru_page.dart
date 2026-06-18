import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class TransaksiBaruPage extends StatelessWidget {
  const TransaksiBaruPage({super.key});

  static const route = '/transaksi-baru';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.grey[800], size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Transaksi Baru',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: PILIH NASABAH
                    Text(
                      'PILIH NASABAH',
                      style: AppTextStyle.extraSmall.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        // Note: Using solid border for now as a fallback for dashed
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5), // grey[100]
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_outline, color: Colors.grey[500], size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tap untuk pilih nasabah',
                              style: AppTextStyle.small.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: DAFTAR SETORAN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DAFTAR SETORAN',
                          style: AppTextStyle.extraSmall.copyWith(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '0 item',
                          style: AppTextStyle.small.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Empty State Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        // Note: Using solid border for now as a fallback
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.add, color: Colors.grey[400], size: 24),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Item Setoran',
                            style: AppTextStyle.title1.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap tombol di bawah untuk menambah item.',
                            style: AppTextStyle.small.copyWith(
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Item Button
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: AppColors.greenDark, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Tambah Item Setoran',
                              style: AppTextStyle.title1.copyWith(
                                color: AppColors.greenDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal item',
                                style: AppTextStyle.small.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                'Rp 0',
                                style: AppTextStyle.title1.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Grand Total',
                                style: AppTextStyle.title1.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Rp 0',
                                style: AppTextStyle.headline1.copyWith(
                                  color: AppColors.greenDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: null, // Disabled state
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: Text(
              'Simpan Transaksi',
              style: AppTextStyle.title1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
