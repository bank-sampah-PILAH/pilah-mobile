import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/pilih_bank_sampah_section.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_layout.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_exit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_step_scaffold.dart';

/// The nasabah half of PIL-204: a calon nasabah, having already completed
/// their profile (including address) on the shared complete_profile step,
/// picks a bank sampah to apply to join.
class RegisterNasabahScreen extends ConsumerStatefulWidget {
  const RegisterNasabahScreen({super.key});

  static const route = '/register-nasabah';

  @override
  ConsumerState<RegisterNasabahScreen> createState() =>
      _RegisterNasabahScreenState();
}

class _RegisterNasabahScreenState extends ConsumerState<RegisterNasabahScreen> {
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
        await ref.read(onboardingProvider.notifier).loadMyMemberships();
    if (!mounted || error != null) return;
    setState(() => _memberships = result ?? const []);
  }

  Future<void> _onSubmit() async {
    // Locked means a membership already exists — usually because the
    // pengurus-entered record auto-linked at login, before this draft was
    // ever sent. There's no new bank to register, but the profile itself
    // still needs to land: OnboardingNotifier.submitNasabahRegistration skips
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
      bankSampahId:
          _isLocked ? _memberships.first.bankSampahId : _selectedBank!.id,
    );
    final (:result, :error) = await ref
        .read(onboardingProvider.notifier)
        .submitNasabahRegistration(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error.displayMessage);
      return;
    }

    // Membership now linked to the account; refresh the cached session so a
    // relaunch mid-flow lands on the right step.
    ref.read(authenticationProvider.notifier).refreshUser();
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

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Daftar Sebagai Nasabah',
      subtitle: 'Pilih bank sampah untuk mengajukan keanggotaan.',
      onExit: () => confirmExitOnboarding(context),
      onUnauthenticated: () => context.go(LoginPage.route),
      progress: const OnboardingStepper(
        currentStep: 2,
        secondStepLabel: 'Pilih Bank Sampah',
      ),
      formKey: _formKey,
      formFields: [
        if (_isLocked) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Text(
              'Saat ini Anda hanya dapat terdaftar di 1 '
              'bank sampah.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        OnboardingFormField(
          label: 'BANK SAMPAH',
          description: 'Bank sampah yang akan menjadi tempat Anda '
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
          const Text(
            'BANK SAMPAH YANG SUDAH TERGABUNG',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.inkSoft,
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey100,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
      footer: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              AppButton(
                label: _isLocked ? 'Lanjutkan' : 'Ajukan Pendaftaran',
                trailingIcon: Icons.arrow_forward,
                isLoading: _isLoading,
                onPressed: _onSubmit,
              ),
              if (ref.read(onboardingProvider.notifier).hasProfileDraft) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Kembali',
                  variant: AppButtonVariant.neutral,
                  onPressed: () => handleOnboardingStepPop(
                    context,
                    didPop: false,
                    isWizardStep: true,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Pengajuan akan ditinjau oleh pengurus bank sampah.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.grey200),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
