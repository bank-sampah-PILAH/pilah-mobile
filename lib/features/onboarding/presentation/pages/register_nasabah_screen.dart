import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/pilih_bank_sampah_section.dart';

/// The nasabah half of PIL-204: a calon nasabah, having already completed
/// their profile (including address) on the shared complete_profile step,
/// picks a bank sampah to apply to join.
class RegisterNasabahScreen extends StatefulWidget {
  const RegisterNasabahScreen({super.key});

  static const route = '/register-nasabah';

  @override
  State<RegisterNasabahScreen> createState() => _RegisterNasabahScreenState();
}

class _RegisterNasabahScreenState extends State<RegisterNasabahScreen> {
  final _formKey = GlobalKey<FormState>();

  BankSampahDirectoryEntity? _selectedBank;
  // Only shown once a submit attempt happens, matching the text fields'
  // AutovalidateMode.onUserInteraction: a blank picker isn't an error before
  // the user has done anything.
  bool _showBankError = false;
  bool _isLoading = false;

  List<NasabahMembershipEntity> _memberships = const [];

  /// PIL-204 scope for now: one membership per nasabah. Any existing
  /// membership — pending, approved, or rejected — locks further
  /// registration rather than letting a second application through.
  bool get _isLocked => _memberships.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadMemberships();
  }

  Future<void> _loadMemberships() async {
    final (:result, :error) =
        await context.read<OnboardingCubit>().loadMyMemberships();
    if (!mounted || error != null) return;
    setState(() => _memberships = result ?? const []);
  }

  Future<void> _onSubmit() async {
    // Locked means a membership already exists — usually because the
    // pengurus-entered record auto-linked at login, before this draft was
    // ever sent. There's no new bank to register, but the profile itself
    // still needs to land: OnboardingCubit.submitNasabahRegistration skips
    // its own registerNasabah call once completing the profile already
    // reaches nasabah_dashboard, so a placeholder bank id here is never
    // actually sent anywhere.
    if (!_isLocked) {
      setState(() => _showBankError = _selectedBank == null);
      final formValid = _formKey.currentState?.validate() ?? false;
      if (!formValid || _selectedBank == null) return;
    }

    setState(() => _isLoading = true);

    final request = RegisterNasabahRequest(
      bankSampahId: _isLocked ? _memberships.first.bankSampahId : _selectedBank!.id,
    );
    final (:result, :error) = await context
        .read<OnboardingCubit>()
        .submitNasabahRegistration(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error.displayMessage);
      return;
    }

    // Membership now linked to the account; refresh the cached session so a
    // relaunch mid-flow lands on the right step.
    context.read<AuthenticationBloc>().add(RefreshUserRequested());
    context.go(locationForAuthStep(result?.nextStep));
  }

  void _showError(String message) {
    AppNotification.showError(context, title: 'Gagal', message: message);
  }

  String _membershipStatusLabel(NasabahMembershipEntity membership) {
    switch (membership.status) {
      case 'pending':
        return 'Menunggu';
      case 'rejected':
        return 'Ditolak';
      default:
        return membership.isActive ? 'Aktif' : 'Nonaktif';
    }
  }

  void _onBankSelected(BankSampahDirectoryEntity bank) {
    setState(() {
      _selectedBank = bank;
      _showBankError = false;
    });
  }

  /// Whether this form is step two of the wizard rather than a destination in
  /// its own right.
  ///
  /// A banked draft is the evidence: it exists only when the profile screen
  /// pushed this route and is still sitting underneath, which is also the only
  /// case where popping leads anywhere useful. Reached any other way — a
  /// relogin whose profile was already complete — there is no page behind
  /// this one and back has to keep meaning "leave onboarding".
  bool get _isWizardStep => context.read<OnboardingCubit>().hasProfileDraft;

  /// Intercepts a back-navigation attempt.
  ///
  /// Mid-wizard the pop is allowed through to the profile screen, which
  /// refills itself from the draft — so anything picked here, and the
  /// profile fields, both stay editable until the final submit.
  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    if (_isWizardStep) {
      _backToProfile();
      return;
    }
    _confirmExit();
  }

  /// Returns to step one, preferring a pop so the profile screen underneath is
  /// revealed rather than rebuilt over the top of this one.
  void _backToProfile() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      context.go('/complete-profile');
    }
  }

  Future<void> _confirmExit() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar dari Pendaftaran?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Progress pengisian data Anda belum '
          'tersimpan dan Anda akan dialihkan ke halaman login.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      context.read<AuthenticationBloc>().add(LogoutRequested());
    }
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationStates>(
      listenWhen: (previous, current) => current is Unauthenticated,
      listener: (context, state) => context.go(LoginPage.route),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop),
        child: Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                      top: 70, left: 24, right: 24, bottom: 40),
                  decoration: const BoxDecoration(color: AppColors.greenDark),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daftar Sebagai Nasabah',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pilih bank sampah untuk mengajukan '
                              'keanggotaan.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _confirmExit,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        tooltip: 'Keluar',
                      ),
                    ],
                  ),
                ),

                // Onboarding stepper: step one (Profil Diri) already landed
                // on the shared complete_profile screen, so it renders done
                // here — this is step two.
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.greenDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.check,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Profil Diri',
                            style: TextStyle(
                              color: AppColors.greenDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 100,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        color: AppColors.greenDark,
                      ),
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.greenDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pilih Bank Sampah',
                            style: TextStyle(
                              color: AppColors.greenDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLocked) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Saat ini Anda hanya dapat terdaftar di 1 '
                                'bank sampah.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.brown[700],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildFormField(
                            label: 'BANK SAMPAH',
                            description:
                                'Bank sampah yang akan menjadi tempat Anda '
                                'menabung sampah',
                            child: PilihBankSampahSection(
                              selectedBank: _selectedBank,
                              onBankSelected: _onBankSelected,
                              hasError: _showBankError,
                              errorText: 'Bank sampah wajib dipilih',
                              enabled: !_isLocked,
                              excludedBankIds: _memberships
                                  .map((membership) => membership.bankSampahId)
                                  .toSet(),
                            ),
                          ),
                          if (_memberships.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              'BANK SAMPAH YANG SUDAH TERGABUNG',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final membership in _memberships)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        membership.bankSampahNama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _membershipStatusLabel(membership),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greenDark,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isLocked
                                          ? 'Lanjutkan'
                                          : 'Ajukan Pendaftaran',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      if (_isWizardStep) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _backToProfile,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              'Kembali',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Pengajuan akan ditinjau oleh pengurus bank sampah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
