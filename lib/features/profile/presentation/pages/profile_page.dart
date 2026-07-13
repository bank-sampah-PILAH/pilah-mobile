import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/services/di.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const route = '/profile';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<ProfileCubit>()..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _waController = TextEditingController();
  bool _waSeeded = false;

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
    _waController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NA';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'superadmin':
        return 'Superadmin';
      case 'pengelola':
      default:
        return 'Pengelola';
    }
  }

  Color _avatarColorFor(String seed) {
    const palette = [
      AppColors.greenDark,
      Color(0xFF7C3AED),
      Color(0xFFD4A843),
      Color(0xFF0F766E),
      Color(0xFF9A3412),
    ];
    if (seed.isEmpty) return palette.first;
    return palette[seed.hashCode.abs() % palette.length];
  }

  /// Signs the user out and returns to login once the bloc reports it, clearing
  /// the app-scoped cubit caches so a later session starts clean.
  void _onLoggedOut(BuildContext context, AuthenticationStates state) {
    if (state is! Unauthenticated) return;
    context.read<NasabahCubit>().reset();
    context.read<HargaCubit>().reset();
    context.read<TransaksiCubit>().reset();
    context.read<DashboardCubit>().reset();
    context.go(LoginPage.route);
  }

  void _seedWaTemplate(BuildContext context, ProfileState state) {
    if (!_waSeeded && state.waTemplate != null) {
      _waController.text = state.waTemplate!.template;
      _waSeeded = true;
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  Future<void> _onSaveSettings() async {
    final err = await context.read<ProfileCubit>().saveWaTemplate(_waController.text.trim());
    if (!mounted) return;
    _snack(err == null ? 'Pengaturan berhasil disimpan' : err.displayMessage, error: err != null);
  }

  Future<void> _onCopyInvite() async {
    final (:url, :error) = await context.read<ProfileCubit>().generateInvite();
    if (!mounted) return;
    if (error != null) {
      _snack(error.displayMessage, error: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: url ?? ''));
    if (!mounted) return;
    _snack('Link undangan disalin ke clipboard!');
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileCubit>().state;
    final authState = context.watch<AuthenticationBloc>().state;
    final auth = authState is Authenticated ? authState.authEntity : null;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthenticationBloc, AuthenticationStates>(listener: _onLoggedOut),
        BlocListener<ProfileCubit, ProfileState>(listener: _seedWaTemplate),
      ],
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
                child: _buildTabBody(profileState, auth),
              ),

              // Bottom Buttons (only visible on Pengaturan Umum tab)
              if (_tabController.index == 0 && profileState.status == ProfileStatus.loaded)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: profileState.isSavingTemplate ? null : _onSaveSettings,
                          icon: profileState.isSavingTemplate
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                          label: Text(
                            profileState.isSavingTemplate ? 'Menyimpan...' : 'Simpan Pengaturan',
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

  Widget _buildTabBody(ProfileState state, AuthEntity? auth) {
    if (state.status == ProfileStatus.loading || state.status == ProfileStatus.initial) {
      return const Center(child: CircularProgressIndicator(color: AppColors.greenDark));
    }
    if (state.status == ProfileStatus.error) {
      return _buildError(state.error);
    }
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPengaturanUmumTab(state, auth),
        _buildManajemenTimTab(state, auth),
      ],
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: Colors.grey[400], size: 48),
            const SizedBox(height: 16),
            Text(
              message ?? 'Gagal memuat data profil',
              textAlign: TextAlign.center,
              style: AppTextStyle.small.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.read<ProfileCubit>().load(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Pengaturan Umum ──────────────────────────────────────────

  Widget _buildPengaturanUmumTab(ProfileState state, AuthEntity? auth) {
    final name = (auth?.name.trim().isNotEmpty ?? false) ? auth!.name : 'Pengguna';
    final bank = state.bankSampah;

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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.greenLight,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
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
                        name,
                        style: AppTextStyle.title1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _roleLabel(auth?.role),
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
          _sectionTitle('PROFIL BANK SAMPAH'),
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
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.greenLight, width: 2),
                    ),
                    child: const Icon(Icons.home_outlined, color: AppColors.greenDark, size: 40),
                  ),
                ),
                const SizedBox(height: 24),
                _buildFormField(
                  label: 'NAMA BANK SAMPAH',
                  value: bank?.nama.isNotEmpty == true ? bank!.nama : '-',
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  label: 'ALAMAT BANK SAMPAH',
                  value: _composeAlamat(bank),
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  label: 'NOMOR HP PENANGGUNG JAWAB',
                  value: bank?.noHpPic.isNotEmpty == true ? bank!.noHpPic : '-',
                  prefixIcon: Icons.phone,
                  iconColor: Colors.pink[400],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildWhatsappTemplate(state),
        ],
      ),
    );
  }

  String _composeAlamat(BankSampahProfile? bank) {
    if (bank == null) return '-';
    final parts = [bank.alamat, bank.kota].where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  // ── Tab 2: Manajemen Tim ────────────────────────────────────────────

  Widget _buildManajemenTimTab(ProfileState state, AuthEntity? auth) {
    final team = state.team;

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
                  'Bagikan link agar pengelola lain bisa bergabung ke bank sampah Anda.',
                  style: AppTextStyle.small.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _onCopyInvite,
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
              _sectionTitle('PENGELOLA TERGABUNG'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${team.length} aktif',
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
          if (team.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                'Belum ada pengelola lain yang tergabung.',
                textAlign: TextAlign.center,
                style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
              ),
            )
          else
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
                  for (int i = 0; i < team.length; i++) ...[
                    if (i > 0)
                      Divider(color: Colors.grey[100], height: 1, thickness: 1, indent: 16, endIndent: 16),
                    _buildMemberRow(team[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(TeamMember member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _avatarColorFor(member.nama),
            child: Text(
              _initials(member.nama),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    member.nama.isNotEmpty ? member.nama : member.email,
                    style: AppTextStyle.small.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (member.isCurrentUser) ...[
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
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.isPrimary ? 'Pengelola Utama' : 'Pengelola',
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

  Widget _sectionTitle(String label) {
    return Row(
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
          label,
          style: AppTextStyle.extraSmall.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String value,
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
            border: Border.all(color: Colors.grey[300]!, width: 1),
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
                  style: AppTextStyle.small.copyWith(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsappTemplate(ProfileState state) {
    final variables = state.waTemplate?.variables ??
        const ['{Nama}', '{Total}', '{Saldo}', '{Tanggal}', '{daftar_item}'];
    final preview = state.waTemplate?.preview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('TEMPLATE NOTIFIKASI WA'),
        const SizedBox(height: 16),
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
              Text(
                'ISI PESAN',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _waController,
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
              Text(
                'Gunakan variabel berikut agar sistem mengisi otomatis:',
                style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final variable in variables) _buildVariableChip(variable),
                ],
              ),
              if (preview != null && preview.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
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
                      Text(
                        preview,
                        style: AppTextStyle.small.copyWith(color: Colors.black87, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariableChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greenLight, width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyle.small.copyWith(
          color: AppColors.greenDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
