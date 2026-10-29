import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/profile/presentation/pages/profil_nasabah_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/navigation_form.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';

import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/domain/wa_template_preview.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/states/profile_state.dart';
import 'package:pilah_mobile/features/profile/presentation/widgets/wa_variable_chips.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, this.isWeb});

  /// Mengganti `kIsWeb`, supaya test dapat memilih bentuk web atau aplikasi.
  final bool? isWeb;

  static const route = AppLocations.profile;

  // Profile state is app-scoped; loading starts in _ProfileView after login.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authenticationProvider);
    final role = state is Authenticated ? state.authEntity.role : null;
    if (role == 'nasabah') return const ProfilNasabahPage();
    if (role == 'pengelola' || role == 'pengelola_induk') {
      return _ProfileView(isWeb: isWeb ?? kIsWeb);
    }
    return const Scaffold(
      body: SafeArea(
        child: Center(child: Text('Silakan masuk untuk melihat profil Anda.')),
      ),
    );
  }
}

class _ProfileView extends ConsumerStatefulWidget {
  const _ProfileView({required this.isWeb});

  final bool isWeb;

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<_ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _waController = TextEditingController();
  final FocusNode _waFocusNode = FocusNode();
  final TextEditingController _namaBankController = TextEditingController();
  final TextEditingController _alamatBankController = TextEditingController();
  final TextEditingController _hpBankController = TextEditingController();
  final _bankFormKey = GlobalKey<FormState>();
  bool _waSeeded = false;
  bool _bankSeeded = false;
  // Covers the whole save (bank profile then WA template) — see _onSaveSettings.
  bool _isSavingSettings = false;

  /// Di browser halaman ini berada di dalam shell dengan rail, bukan didorong
  /// di atasnya, jadi memakai gutter dan judul halaman tab web.
  bool get _webShell =>
      NavigationForm.resolve(
        isWeb: widget.isWeb,
        width: MediaQuery.sizeOf(context).width,
      ) !=
      NavigationForm.bottomBar;

  double get _gutter => _webShell ? AppSpacing.webGutter : 16;

  // Isi form saat dimuat atau terakhir disimpan; pembanding untuk [_dirty].
  String _baseWa = '';
  String _baseNama = '';
  String _baseAlamat = '';
  String _baseHp = '';

  /// Ada isian yang berbeda dari yang tersimpan, atau logo baru yang dipilih
  /// tetapi belum disimpan.
  bool get _dirty =>
      _waController.text != _baseWa ||
      _namaBankController.text != _baseNama ||
      _alamatBankController.text != _baseAlamat ||
      _hpBankController.text != _baseHp ||
      ref.read(profileProvider).selectedLogoBytes != null;

  void _rebuildOnEdit() {
    if (mounted) setState(() {});
  }

  void _markSaved() {
    _baseWa = _waController.text;
    _baseNama = _namaBankController.text;
    _baseAlamat = _alamatBankController.text;
    _baseHp = _hpBankController.text;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // Seed cached state before refreshing so revisits keep their form values.
    _seed(ref.read(profileProvider));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(profileProvider.notifier).load(silent: true);
    });
    for (final c in [
      _waController,
      _namaBankController,
      _alamatBankController,
      _hpBankController,
    ]) {
      c.addListener(_rebuildOnEdit);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _waController.dispose();
    _waFocusNode.dispose();
    _namaBankController.dispose();
    _alamatBankController.dispose();
    _hpBankController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'NA';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'superadmin':
        return 'Superadmin';
      case 'pengelola_induk':
        return 'Pengelola Induk';
      case 'pengelola':
      default:
        return 'Pengurus';
    }
  }

  Color _avatarColorFor(String seed) {
    const palette = AppColors.avatarFills;
    if (seed.isEmpty) return palette.first;
    return palette[seed.hashCode.abs() % palette.length];
  }

  /// Returns to login once authentication reports sign-out. Clearing app-
  /// scoped state is handled centrally in [App], so it happens on
  /// every logout path rather than only the one that passes through this page.
  void _onLoggedOut(BuildContext context, AuthenticationStates state) {
    if (state is! Unauthenticated) return;
    context.go(LoginPage.route);
  }

  /// Copies the loaded profile into the form controllers, once per field.
  ///
  /// Seeding the WA field is what makes saving safe: [_onSaveSettings] writes
  /// whatever the field holds, so a field left empty over a stored template
  /// would blank it on a save the user made purely for the bank details.
  void _seed(ProfileState state) {
    if (!_waSeeded && state.waTemplate != null) {
      _waController.text = state.waTemplate!.template;
      _baseWa = _waController.text;
      _waSeeded = true;
    }
    if (!_bankSeeded && state.bankSampah != null) {
      final bank = state.bankSampah!;
      _namaBankController.text = bank.nama;
      _alamatBankController.text = bank.alamat;
      _hpBankController.text = bank.noHpPic;
      _baseNama = _namaBankController.text;
      _baseAlamat = _alamatBankController.text;
      _baseHp = _hpBankController.text;
      _bankSeeded = true;
    }
  }

  /// Inserts [variable] (e.g. `{Nama}`) into the WA template at the current
  /// cursor position, replacing any active selection. When the field has never
  /// been focused the selection is invalid, so the variable is appended to the
  /// end instead. Afterwards the cursor sits just past the inserted text and the
  /// field keeps focus, so consecutive chip taps stack predictably and the live
  /// preview (listening on the controller) refreshes immediately.
  void _insertVariable(String variable) {
    final text = _waController.text;
    final selection = _waController.selection;
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, variable);
    _waController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + variable.length),
    );
    _waFocusNode.requestFocus();
  }

  void _snack(String message, {bool error = false}) {
    if (error) {
      AppNotification.showError(context, title: 'Gagal', message: message);
    } else {
      AppNotification.showSuccess(context, title: 'Berhasil', message: message);
    }
  }

  Future<void> _onSaveSettings() async {
    if (!(_bankFormKey.currentState?.validate() ?? false)) return;
    final cubit = ref.read(profileProvider.notifier);

    // One flag for the whole save rather than the provider's `isSavingTemplate`,
    // which only covers the template write: the bank profile is saved first, and
    // the button has to read "Menyimpan..." for that leg too.
    setState(() => _isSavingSettings = true);

    final bankErr = await cubit.updateBankSampah(
      nama: _namaBankController.text.trim(),
      alamat: _alamatBankController.text.trim(),
      noHpPic: _hpBankController.text.trim(),
    );
    if (!mounted) return;
    if (bankErr != null) {
      setState(() => _isSavingSettings = false);
      _snack(bankErr.displayMessage, error: true);
      return;
    }

    // Writes whatever the field shows, which is the point of a WYSIWYG editor —
    // an emptied field is a deliberate "drop my custom template", and the
    // transaksi notification falls back to the default when it reads back blank.
    // This is only safe because the controller is seeded from the stored
    // template on mount as well as on provider updates (see [_seed]); a
    // field that silently stayed empty would blank the template on a save the
    // user made purely for the bank fields.
    final waErr = await cubit.saveWaTemplate(_waController.text.trim());
    if (!mounted) return;
    if (waErr == null) _markSaved();
    setState(() => _isSavingSettings = false);
    _snack(
      waErr == null ? 'Pengaturan berhasil disimpan' : waErr.displayMessage,
      error: waErr != null,
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk kembali untuk mengakses akun ini.',
      confirmLabel: 'Ya, Keluar',
      destructive: true,
    );
    if (confirmed && mounted) {
      ref.read(authenticationProvider.notifier).logout();
    }
  }

  Future<void> _onCopyInvite() async {
    final (:url, :error) =
        await ref.read(profileProvider.notifier).generateInvite();
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
    ref.listen(profileProvider, (_, next) => _seed(next));
    ref.listen(authenticationProvider, (_, state) {
      _onLoggedOut(context, state);
    });
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authenticationProvider);
    final auth = authState is Authenticated ? authState.authEntity : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // The tabs scroll across the whole body, so their scrollbar is at the
        // window edge; the frame keeps the content to a readable column.
        child: ContentFrame(
          child: Column(
            children: [
              // Di browser rail di kiri adalah jalan keluarnya, jadi tidak ada
              // tombol kembali; judulnya mengikuti halaman tab web lain.
              ContentInset(
                child: _webShell
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.webGutter,
                          AppSpacing.webTop,
                          AppSpacing.webGutter,
                          AppSpacing.md,
                        ),
                        child: AppPageHeader(title: 'Profil & Pengaturan'),
                      )
                    : AppBackHeader(
                        title: 'Profil & Pengaturan',
                        onBack: () => context.canPop()
                            ? context.pop()
                            : context.go(AppLocations.dashboard),
                      ),
              ),

              // Tab Bar
              ContentInset(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: _gutter),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    // Di web tab rata kiri selebar isinya, bukan dibagi rata
                    // ke seluruh lebar halaman.
                    isScrollable: _webShell,
                    tabAlignment:
                        _webShell ? TabAlignment.start : TabAlignment.fill,
                    labelColor: AppColors.greenDark,
                    unselectedLabelColor: AppColors.grey200,
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
              ),

              // Tab Views
              Expanded(
                child: _buildTabBody(profileState, auth),
              ),

              // Bar bawah: hanya Simpan, dan hanya di tab Pengaturan Umum.
              if (_tabController.index == 0 &&
                  profileState.status == ProfileStatus.loaded)
                ContentInset(child: _buildActionBar()),
            ],
          ),
        ),
      ),
    );
  }

  /// Bar bawah berisi Simpan saja, dan hanya ada bila ada yang berubah. Di web
  /// ia rata kanan selebar isinya; di aplikasi selebar layar, dengan petunjuk di
  /// atasnya. Keluar ada di paling bawah isi halaman.
  Widget _buildActionBar() {
    final dirty = _dirty;
    // Tidak ada bar sama sekali sampai ada yang berubah; ia muncul bersama
    // petunjuknya dan hilang lagi setelah tersimpan.
    if (!dirty && !_isSavingSettings) return const SizedBox.shrink();
    final showHint = dirty && !_isSavingSettings;
    final save = AppButton(
      label: _isSavingSettings ? 'Menyimpan...' : 'Simpan Pengaturan',
      icon: Icons.save_outlined,
      expand: !_webShell,
      leading: _isSavingSettings
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : null,
      onPressed: _isSavingSettings ? null : _onSaveSettings,
    );
    final hint = Text(
      'Perubahan belum disimpan',
      style: AppTextStyle.small.copyWith(color: AppColors.warning),
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _gutter,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: _webShell
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showHint) ...[hint, const SizedBox(width: AppSpacing.lg)],
                save,
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHint) ...[hint, const SizedBox(height: AppSpacing.sm)],
                save,
              ],
            ),
    );
  }

  Widget _buildTabBody(ProfileState state, AuthEntity? auth) {
    if (state.status == ProfileStatus.loading ||
        state.status == ProfileStatus.initial) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.greenDark));
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
            const Icon(Icons.cloud_off, color: AppColors.grey200, size: 48),
            const SizedBox(height: 16),
            Text(
              message ?? 'Gagal memuat data profil',
              textAlign: TextAlign.center,
              style: AppTextStyle.small.copyWith(color: AppColors.grey100),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(profileProvider.notifier).load(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Pengaturan Umum ──────────────────────────────────────────

  /// Kartu akun, sama di web dan di aplikasi: putih dengan garis tepi, berisi
  /// identitas. Di web Keluar ada di kanannya; di aplikasi Keluar ada di paling
  /// bawah halaman ([_buildLogoutButton]).
  Widget _buildAccountCard(String name, AuthEntity? auth) {
    final email = auth?.email.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.greenLight,
            child: Text(
              _initials(name),
              style: AppTextStyle.title1.copyWith(color: AppColors.greenDark),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.title1.copyWith(color: AppColors.black),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyle.small.copyWith(color: AppColors.grey100),
                  ),
                const SizedBox(height: AppSpacing.sm),
                CustomStatusBadge(statusText: _roleLabel(auth?.role)),
              ],
            ),
          ),
          if (_webShell) ...[
            const SizedBox(width: AppSpacing.lg),
            AppButton(
              label: 'Keluar dari Aplikasi',
              variant: AppButtonVariant.destructiveOutlined,
              size: AppButtonSize.compact,
              icon: Icons.logout,
              expand: false,
              onPressed: _confirmLogout,
            ),
          ],
        ],
      ),
    );
  }

  /// Keluar di aplikasi, di paling bawah isi halaman: aksi akun yang jarang
  /// dipakai, jauh dari Simpan supaya tidak tertekan tanpa sengaja.
  Widget _buildLogoutButton() => AppButton(
        label: 'Keluar dari Aplikasi',
        variant: AppButtonVariant.destructiveOutlined,
        icon: Icons.logout,
        onPressed: _confirmLogout,
      );

  /// Jarak kiri dan kanan isi tab: gutter web, atau 24 di desktop non-web dan
  /// 16 di bawahnya.
  double _sideGutter(bool isDesktop) {
    if (_webShell) return _gutter;
    return isDesktop ? 24.0 : 16.0;
  }

  Widget _buildPengaturanUmumTab(ProfileState state, AuthEntity? auth) {
    final name =
        (auth?.name.trim().isNotEmpty ?? false) ? auth!.name : 'Pengguna';
    final accountCard = _buildAccountCard(name, auth);
    final bankProfile = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('PROFIL BANK SAMPAH'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _bankFormKey,
            child: Column(
              children: [
                _buildLogoPicker(state),
                const SizedBox(height: 24),
                _buildEditableField(
                  label: 'NAMA BANK SAMPAH',
                  controller: _namaBankController,
                  validator: _validateNamaBank,
                ),
                const SizedBox(height: 16),
                _buildEditableField(
                  label: 'ALAMAT BANK SAMPAH',
                  controller: _alamatBankController,
                  maxLines: 2,
                  validator: _validateAlamatBank,
                ),
                const SizedBox(height: 16),
                _buildEditableField(
                  label: 'NOMOR HP PENANGGUNG JAWAB',
                  controller: _hpBankController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
                  iconColor: AppColors.inkSoft,
                  validator: _validateNomorHpPic,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= LayoutBreakpoint.expandedMinWidth;
        final whatsappTemplate = _buildWhatsappTemplate(state);

        return AppRefreshIndicator(
          onRefresh: () =>
              ref.read(profileProvider.notifier).load(silent: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: ContentFrame.insetOf(context).add(EdgeInsets.fromLTRB(
                _sideGutter(isDesktop), 16, _sideGutter(isDesktop), 24)),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LayoutBreakpoint.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    accountCard,
                    const SizedBox(height: 32),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: bankProfile),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: whatsappTemplate),
                        ],
                      )
                    else ...[
                      bankProfile,
                      const SizedBox(height: 32),
                      whatsappTemplate,
                    ],
                    if (!_webShell) ...[
                      const SizedBox(height: 32),
                      _buildLogoutButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _validateNamaBank(String? value) =>
      value == null || value.trim().length < 3
          ? 'Nama minimal 3 karakter'
          : null;

  String? _validateAlamatBank(String? value) =>
      value == null || value.trim().length < 10
          ? 'Alamat wajib diisi (minimal 10 karakter)'
          : null;

  String? _validateNomorHpPic(String? value) =>
      value == null || value.trim().isEmpty ? 'Nomor HP wajib diisi' : null;

  /// The bank sampah logo, and the control for replacing it.
  ///
  /// Tapping anywhere on the circle opens the gallery. The camera badge is the
  /// only thing saying so — an avatar that happens to be tappable reads as
  /// decoration, and the logo was a static icon before this, so nobody has a
  /// reason to try. It is painted, not pressed: the badge is small enough that
  /// making it the target would shrink a comfortable 88px circle down to 28.
  ///
  /// A picked file wins over the stored logo. Between choosing an image and
  /// saving, the local file *is* the answer to "what will this logo be", and
  /// showing the old one until save would read as a pick that did not register.
  Widget _buildLogoPicker(ProfileState state) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () async {
                try {
                  await ref.read(profileProvider.notifier).pickLogo();
                } catch (_) {
                  if (!mounted) return;
                  AppNotification.showError(context,
                      title: 'Gagal',
                      message: 'Foto tidak dapat dibaca. Silakan coba lagi.');
                }
              },
              child: Container(
                width: _logoDiameter,
                height: _logoDiameter,
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.greenLight, width: 2),
                ),
                child: ClipOval(child: _buildLogoContent(state)),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.greenDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fills the circle with the most current logo available, falling back until
  /// something can be drawn.
  Widget _buildLogoContent(ProfileState state) {
    final bytes = state.selectedLogoBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: _logoDiameter,
        height: _logoDiameter,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _logoPlaceholder,
      );
    }

    final url = state.bankSampah?.fotoLogo;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: _logoDiameter,
        height: _logoDiameter,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _logoPlaceholder,
        // A logo that is set but unreachable falls back to the same placeholder
        // as no logo at all. The distinction matters to a superadmin reviewing
        // evidence, which is why showProofImageDialog keeps the two apart; here
        // it is the user's own logo on their own settings page, and a broken
        // glyph in the middle of a form is only noise.
        errorBuilder: (_, __, ___) => _logoPlaceholder,
      );
    }

    return _logoPlaceholder;
  }

  static const double _logoDiameter = 88;

  static const Widget _logoPlaceholder = Center(
    child: Icon(Icons.home_outlined, color: AppColors.greenDark, size: 40),
  );

  // ── Tab 2: Manajemen Tim ────────────────────────────────────────────

  Widget _buildManajemenTimTab(ProfileState state, AuthEntity? auth) {
    final team = state.team;

    // Only the Pengelola Utama (owner) may invite. Their own roster row is the
    // one flagged both `is_current_user` and `is_primary_pengelola`; invited
    // (secondary) pengelola have `is_primary_pengelola == false`. This mirrors
    // the backend, which restricts the invite endpoint to the primary pengelola
    // (a non-owner tapping the card would only get a 403). If the team roster
    // failed to load it is empty, so the card fails closed (hidden) rather than
    // showing an action that cannot succeed.
    final isPengelolaUtama = team.any((m) => m.isCurrentUser && m.isPrimary);

    return AppRefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).load(silent: true),
      // A Builder, so the inset comes from the frame below the page body.
      child: Builder(
        builder: (context) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ContentFrame.insetOf(context)
              .add(const EdgeInsets.fromLTRB(16, 20, 16, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invite Banner — owner only. Both the banner and its trailing gap
              // are guarded so hiding it leaves no dangling spacing above the list.
              if (isPengelolaUtama) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.greenDark,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Undang Pengurus Baru',
                        style: AppTextStyle.title1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bagikan link agar pengurus lain bisa bergabung ke bank sampah Anda.',
                        style: AppTextStyle.small.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Salin Link Undangan',
                        variant: AppButtonVariant.outlined,
                        icon: Icons.copy,
                        onPressed: _onCopyInvite,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('PENGELOLA TERGABUNG'),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
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
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Belum ada pengurus lain yang tergabung.',
                    textAlign: TextAlign.center,
                    style:
                        AppTextStyle.small.copyWith(color: AppColors.grey100),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < team.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              color: AppColors.fill,
                              height: 1,
                              thickness: 1,
                              indent: 16,
                              endIndent: 16),
                        _buildMemberRow(team[i]),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
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
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (member.isCurrentUser) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.greenDark,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
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
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              member.isPrimary ? 'Pengurus Utama' : 'Pengurus',
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
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyle.extraSmall.copyWith(
            color: AppColors.grey100,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    Color? iconColor,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.extraSmall.copyWith(
            color: AppColors.grey100,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyle.small.copyWith(color: AppColors.black),
          decoration: appInputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: iconColor, size: 20)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsappTemplate(ProfileState state) {
    final variables = state.waTemplate?.variables ??
        const ['{Nama}', '{Total}', '{Saldo}', '{Tanggal}', '{daftar_item}'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('TEMPLATE NOTIFIKASI WA'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert Info Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        color: AppColors.greenDark, size: 20),
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
                  color: AppColors.grey100,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _waController,
                focusNode: _waFocusNode,
                minLines: 3,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: appInputDecoration(),
                style: AppTextStyle.small.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 24),
              Text(
                'Gunakan variabel berikut agar sistem mengisi otomatis:',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
              const SizedBox(height: 12),
              WaVariableChips(
                variables: variables,
                onInsert: _insertVariable,
              ),
              // Live preview: rebuilds only this block (not the page) on every
              // keystroke or chip insert, so the cursor never jumps and fast
              // typing stays smooth.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _waController,
                builder: (context, value, _) {
                  final rendered = renderWaPreview(value.text);
                  if (rendered.trim().isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREVIEW PESAN',
                          style: AppTextStyle.extraSmall.copyWith(
                            color: AppColors.grey100,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rendered,
                          // No maxLines / overflow: the preview wraps and grows
                          // freely inside the scrollable tab.
                          softWrap: true,
                          style: AppTextStyle.small
                              .copyWith(color: AppColors.black, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
