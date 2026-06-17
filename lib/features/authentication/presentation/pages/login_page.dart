import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/product/presentation/home/pages/product_home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const route = '/login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Background Blob (Top Right)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  color: AppColors.greenLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Background Blob (Bottom Left)
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  color: AppColors.greenLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Logo Section
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.greenDark,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        'PILAH',
                        style: AppTextStyle.headline1.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        'Sistem Manajemen Bank Sampah',
                        style: AppTextStyle.small.copyWith(
                          color: AppColors.grey100,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.greenDark,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bank Sampah BTH, Depok',
                              style: AppTextStyle.small.copyWith(
                                color: AppColors.greenDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Welcome Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardOffWhite,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Selamat datang kembali ',
                                  style: AppTextStyle.title1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('👋', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Masuk untuk mengelola transaksi setoran, data nasabah, dan laporan bank sampah Anda.',
                              style: AppTextStyle.small.copyWith(
                                color: AppColors.grey100,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Login Button
                      OutlinedButton(
                        onPressed: () {
                          // Dummy navigation for now
                          context.goNamed(ProductHomePage.route);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Generic colored icon placeholder for Google 'G' logo
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.g_mobiledata,
                                  color: Colors.blue,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Masuk dengan Google',
                              style: AppTextStyle.headline3.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Hanya untuk Pengelola & Admin terdaftar • Aman & Terenkripsi',
                              textAlign: TextAlign.center,
                              style: AppTextStyle.extraSmall.copyWith(
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
