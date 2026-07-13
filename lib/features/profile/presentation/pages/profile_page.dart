import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const route = '/profile';

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Signs the user out: the bloc revokes the refresh token and clears local
  /// tokens; when it reports [Unauthenticated] we clear the app-scoped cubit
  /// caches and return to login.
  void _onLoggedOut(BuildContext context, AuthenticationStates state) {
    if (state is! Unauthenticated) return;
    context.read<NasabahCubit>().reset();
    context.read<HargaCubit>().reset();
    context.read<TransaksiCubit>().reset();
    context.read<DashboardCubit>().reset();
    context.go(LoginPage.route);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationStates>(
      listener: _onLoggedOut,
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
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
                  const SizedBox(width: 36),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.greenDark,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: AppTextStyle.small.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: AppTextStyle.small.copyWith(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                indicatorColor: AppColors.greenDark,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Pengaturan Umum'),
                  Tab(text: 'Manajemen Tim'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPengaturanUmumTab(),
                  _buildManajemenTimTab(),
                ],
              ),
            ),

            // Bottom Buttons (only visible on Pengaturan Umum tab)
            if (_tabController.index == 0)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.transparent,
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
                          context.read<AuthenticationBloc>().add(LogoutRequested());
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
      ),
    );
  }

  // ── Tab 1: Pengaturan Umum ──────────────────────────────────────────

  Widget _buildPengaturanUmumTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  isFocused: true,
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
          _buildWhatsappTemplate(),
        ],
      ),
    );
  }

  // ── Tab 2: Manajemen Tim ────────────────────────────────────────────

  Widget _buildManajemenTimTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invite Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.greenDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Undang Pengelola Baru',
                  style: AppTextStyle.title1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bagikan link agar pengelola lain bisa bergabung ke Bank Sampah BTH.',
                  style: AppTextStyle.small.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link undangan disalin ke clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: AppColors.greenDark, size: 18),
                    label: Text(
                      'Salin Link Undangan',
                      style: AppTextStyle.small.copyWith(
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.greenDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                    'PENGELOLA TERGABUNG',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '3 aktif',
                  style: AppTextStyle.extraSmall.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Member List Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMemberRow(
                  initials: 'AF',
                  name: 'Ahmad Fadil',
                  avatarColor: AppColors.greenDark,
                  isCurrentUser: true,
                ),
                Divider(color: Colors.grey[100], height: 1, thickness: 1, indent: 16, endIndent: 16),
                _buildMemberRow(
                  initials: 'RP',
                  name: 'Rina Puspita',
                  avatarColor: const Color(0xFF7C3AED),
                  isCurrentUser: false,
                ),
                Divider(color: Colors.grey[100], height: 1, thickness: 1, indent: 16, endIndent: 16),
                _buildMemberRow(
                  initials: 'DS',
                  name: 'Dimas Saputra',
                  avatarColor: const Color(0xFFD4A843),
                  isCurrentUser: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow({
    required String initials,
    required String name,
    required Color avatarColor,
    required bool isCurrentUser,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTextStyle.small.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greenDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Anda',
                          style: AppTextStyle.extraSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
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
    );
  }

  // ── Shared Helpers ──────────────────────────────────────────────────

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

  Widget _buildWhatsappTemplate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              'TEMPLATE NOTIFIKASI WA',
              style: AppTextStyle.extraSmall.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Container for WA settings
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Info Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: AppColors.greenDark, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pesan otomatis dikirim setelah transaksi',
                        style: AppTextStyle.small.copyWith(
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Label ISI PESAN
              Text(
                'ISI PESAN',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              
              // Text Field
              TextField(
                controller: TextEditingController(text: 'Halo [Nama], setoran sampahmu senilai [Total] sudah kami catat ya. Saldo tabunganmu sekarang adalah [Saldo].\nTerima kasih! 🌿'),
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.greenDark),
                  ),
                ),
                style: AppTextStyle.small.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 24),
              
              // Variables Description
              Text(
                'Gunakan variabel berikut agar sistem mengisi otomatis:',
                style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
              
              // Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildVariableChip('[Nama]', true),
                  _buildVariableChip('[Total]', true),
                  _buildVariableChip('[Saldo]', true),
                  _buildVariableChip('[Tanggal]', false),
                  _buildVariableChip('[daftar_item]', false, isBlue: true),
                ],
              ),
              const SizedBox(height: 24),
              
              // Preview Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREVIEW PESAN',
                      style: AppTextStyle.extraSmall.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyle.small.copyWith(color: Colors.black87, height: 1.5),
                        children: [
                          const TextSpan(text: 'Halo '),
                          TextSpan(
                            text: 'Budi Santoso',
                            style: AppTextStyle.small.copyWith(color: AppColors.greenDark, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ', setoran sampahmu senilai '),
                          TextSpan(
                            text: 'Rp 15.600',
                            style: AppTextStyle.small.copyWith(color: AppColors.greenDark, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' sudah kami catat ya. Saldo tabunganmu sekarang adalah '),
                          TextSpan(
                            text: 'Rp 141.100',
                            style: AppTextStyle.small.copyWith(color: AppColors.greenDark, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '.\nTerima kasih! 🌿'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariableChip(String label, bool isSelected, {bool isBlue = false}) {
    final bgColor = isBlue 
        ? Colors.cyan[50] 
        : isSelected 
            ? AppColors.greenLight.withValues(alpha: 0.3) 
            : Colors.transparent;
    final textColor = isBlue
        ? Colors.cyan[700]
        : isSelected
            ? AppColors.greenDark
            : Colors.grey[600];
    final borderColor = isBlue
        ? Colors.transparent
        : isSelected
            ? AppColors.greenLight
            : Colors.grey[300];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor!, width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyle.small.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
