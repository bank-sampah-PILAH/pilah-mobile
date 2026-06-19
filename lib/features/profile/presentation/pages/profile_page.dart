import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const route = '/profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(
                    'Profil & Pengaturan',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.settings_outlined, color: Colors.grey[800], size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // User Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.greenLight,
                      child: Text(
                        'IS',
                        style: TextStyle(
                          color: Colors.white,
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
                            'Ibu Sari',
                            style: AppTextStyle.title1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'sari@banksampahbth.id',
                            style: AppTextStyle.small.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Pengelola',
                              style: AppTextStyle.extraSmall.copyWith(
                                color: AppColors.greenDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_square, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Section Title
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.greenDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PROFIL BANK SAMPAH',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Form Card
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
                    // Home Icon
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.greenLight, width: 2),
                            ),
                            child: const Icon(Icons.home_outlined, color: AppColors.greenDark, size: 40),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.greenDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Field 1
                    _buildFormField(
                      label: 'NAMA BANK SAMPAH',
                      value: 'Bank Sampah BTH',
                      isFocused: true, // green border
                    ),
                    const SizedBox(height: 16),
                    
                    // Field 2
                    _buildFormField(
                      label: 'ALAMAT BANK SAMPAH',
                      value: 'Kel. Kukusan, Beji, Depok',
                    ),
                    const SizedBox(height: 16),
                    
                    // Field 3
                    _buildFormField(
                      label: 'NOMOR HP PENANGGUNG JAWAB',
                      value: '0812-3456-7890',
                      prefixIcon: Icons.phone,
                      iconColor: Colors.pink[400],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoAplikasi(),
            ],
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.grey[50]!, Colors.transparent],
            stops: const [0.65, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                label: Text(
                  'Simpan Pengaturan',
                  style: AppTextStyle.title1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go(LoginPage.route);
                },
                icon: Icon(Icons.logout, color: Colors.red[600], size: 20),
                label: Text(
                  'Keluar dari Aplikasi',
                  style: AppTextStyle.title1.copyWith(
                    color: Colors.red[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: Colors.red[200]!),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
    );
  }

  Widget _buildInfoAplikasi() {
    return Container(
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
          // Row 1
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time, color: Color(0xFF7C3AED), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Versi Aplikasi',
                        style: AppTextStyle.title1.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PILAH v1.0.0',
                        style: AppTextStyle.small.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Terbaru',
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 1, thickness: 1),
          // Row 2
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dokumentasi PRD',
                        style: AppTextStyle.title1.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fasilkom UI · 2026',
                        style: AppTextStyle.small.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String value,
    bool isFocused = false,
    IconData? prefixIcon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.extraSmall.copyWith(
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused ? AppColors.greenDark : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, color: iconColor, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyle.small.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
