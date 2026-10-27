import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_date_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/invite_acceptance.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/invite_acceptance_notice.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_layout.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_exit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_form_fields.dart';

const _genderMaleApiValue = 'laki-laki';
const _genderMaleLabel = 'Laki-laki';
const _registerBankSampahRoute = '/register-bank-sampah';
const _dashboardRoute = '/dashboard';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  final bool isInviteMode;

  const CompleteProfileScreen({super.key, this.isInviteMode = false});

  static const route = '/complete-profile';

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  /// Invite mode is whatever the store says, with the constructor flag as a
  /// hint on top.
  ///
  /// The store is asked directly rather than trusted to have been read at route
  /// build time: this screen is also reached by routes that never set the flag
  /// (a login that resolves to `complete_profile`, a re-entry after logout), and
  /// on those the two-step stepper used to reappear for a user who is joining an
  /// existing bank sampah and will never see step 2.
  bool get _isInviteMode =>
      widget.isInviteMode || di<InviteTokenStore>().hasToken;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alamatController = TextEditingController();
  String? _gender;
  DateTime? _selectedDob;
  bool _isLoading = false;

  /// Only nasabah accounts have a use for a personal address here —
  /// pengelola/pengelola induk give their organization's address on a
  /// separate step.
  bool get _isNasabah {
    final authState = ref.read(authenticationProvider);
    return authState is Authenticated && authState.authEntity.role == 'nasabah';
  }

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    // An invite link can arrive while this screen is already on top, and the
    // router cannot announce it: the redirect resolves back to
    // `/complete-profile`, which produces a `RouteMatchList` equal to the
    // current one, and `GoRouterDelegate.setNewRoutePath` returns early without
    // notifying — so neither the route builder nor this screen would rebuild,
    // and the two-step stepper would stay up for a user who will never see step
    // two. Listening to the store closes that gap.
    //
    // A rebuild, not a remount: whatever the user has already typed survives.
    di<InviteTokenStore>().addListener(_onInviteTokenChanged);
  }

  void _onInviteTokenChanged() {
    if (mounted) setState(() {});
  }

  /// Refills the form from the draft banked on the way to step two.
  ///
  /// This is what makes "Kembali" from the registration form a real back
  /// button. The screen is rebuilt from scratch on the way back — the route
  /// pushed over it does not preserve this State — so without this the user
  /// would return to an empty form and have to retype everything, which is the
  /// whole reason the wizard defers the profile call.
  ///
  /// Reads straight from the provider rather than waiting for a state emission:
  /// the draft is not part of [OnboardingState], and the controllers have to be
  /// populated before the first build or the fields flash empty.
  void _restoreDraft() {
    final draft = ref.read(onboardingProvider.notifier).profileDraft;
    if (draft == null) {
      _prefillFromSavedProfile();
      return;
    }

    _nameController.text = draft.nama;
    _phoneController.text = draft.noHp;
    _alamatController.text = draft.alamat;
    _gender = draft.jenisKelamin == _genderMaleApiValue
        ? _genderMaleLabel
        : 'Perempuan';

    // Stored as the ISO string the API wants; the picker and the field need a
    // DateTime and dd/MM/yyyy back.
    final parsed = DateTime.tryParse(draft.tanggalLahir);
    if (parsed != null) {
      _selectedDob = parsed;
      _dobController.text = _displayDate(parsed);
    }
  }

  /// Prefills the form from the account's own saved profile when there is no
  /// wizard draft to restore instead (a draft always wins — it represents
  /// more recent input than whatever the backend last saved).
  ///
  /// Covers both the plain Google-name fallback the backend has always
  /// applied and a nasabah synced from a pengurus-entered record (PIL-154):
  /// without this, neither is visible here, since this screen otherwise only
  /// ever restores from the in-memory wizard draft and starts blank
  /// regardless of what the account already has saved.
  void _prefillFromSavedProfile() {
    final authState = ref.read(authenticationProvider);
    if (authState is! Authenticated) return;
    final auth = authState.authEntity;

    if (auth.name.isNotEmpty) _nameController.text = auth.name;
    if (auth.noHp.isNotEmpty) {
      _phoneController.text = _localPhoneDigits(auth.noHp);
    }
    if (_isNasabah && auth.alamat.isNotEmpty) {
      _alamatController.text = auth.alamat;
    }
    if (auth.jenisKelamin.isNotEmpty) {
      _gender = auth.jenisKelamin == _genderMaleApiValue
          ? _genderMaleLabel
          : 'Perempuan';
    }

    final tanggalLahir = auth.tanggalLahir;
    if (tanggalLahir != null) {
      final parsed = DateTime.tryParse(tanggalLahir);
      if (parsed != null) {
        _selectedDob = parsed;
        _dobController.text = _displayDate(parsed);
      }
    }
  }

  String _displayDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  /// Strips a country-code or leading-zero prefix from a saved phone number
  /// so it fits the field's own digits-only, `8...`-starting format.
  ///
  /// The backend normalizes and stores `no_hp` as `+62{national}`
  /// (`normalize_indonesian_phone`), but this field pairs a fixed `+62`
  /// prefix widget with a validator expecting just the national digits —
  /// prefilling the raw saved value doubles the prefix and the field can
  /// never pass its own validation until the user deletes and retypes it.
  String _localPhoneDigits(String noHp) =>
      noHp.replaceFirst(RegExp(r'^\+?62'), '').replaceFirst(RegExp(r'^0'), '');

  @override
  void dispose() {
    di<InviteTokenStore>().removeListener(_onInviteTokenChanged);
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showAppDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = _displayDate(picked);
      });
    }
  }

  /// Whether finishing this form leads to registering a brand-new bank sampah.
  ///
  /// Only that path may defer the profile call, because only there is the next
  /// destination knowable without asking. `AuthService.user_state` reads: an
  /// account with no bank sampah gets `register_bank_sampah` the moment its
  /// profile completes, full stop. An account that already has one instead gets
  /// `approval_pending`, `registration_rejected` or `dashboard` depending on its
  /// status — a verdict only the backend can give, so those keep sending the
  /// profile immediately and routing on the answer.
  bool get _startsNewRegistration {
    final authState = ref.read(authenticationProvider);
    if (authState is! Authenticated) return false;
    return authState.authEntity.role == 'pengelola' &&
        authState.authEntity.bankSampahStatus == null;
  }

  /// Whether finishing this form banks the draft and pushes the nasabah
  /// bank-sampah picker next, rather than submitting straight away.
  ///
  /// Unlike [_startsNewRegistration], reaching this screen does NOT mean the
  /// account has no membership yet: a pengurus-entered Nasabah record
  /// matching this account's verified email auto-links on login
  /// (`AuthService._sync_nasabah_prefill`) while the profile is still
  /// incomplete, so `next_step` after submitting can already be
  /// `nasabah_dashboard`. That case is handled downstream in
  /// `OnboardingNotifier.submitNasabahRegistration`, which skips the
  /// registration call entirely when the profile step alone finishes
  /// onboarding — this getter only decides whether to defer to that wizard
  /// step at all.
  bool get _startsNasabahRegistration {
    final authState = ref.read(authenticationProvider);
    return authState is Authenticated && authState.authEntity.role == 'nasabah';
  }

  String _isoDate(DateTime date) =>
      "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<void> _onSaveAndContinue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Latched for the whole submit: redeeming the invite clears the token,
    // which would otherwise flip [_isInviteMode] halfway through.
    final isInvite = _isInviteMode;

    final request = CompleteProfileRequest(
      nama: _nameController.text.trim(),
      jenisKelamin:
          _gender == _genderMaleLabel ? _genderMaleApiValue : 'perempuan',
      tanggalLahir: _selectedDob != null ? _isoDate(_selectedDob!) : '',
      noHp: _phoneController.text.trim(),
      alamat: _isNasabah ? _alamatController.text.trim() : '',
    );

    final notifier = ref.read(onboardingProvider.notifier);

    // Condition B — a new bank sampah is coming next, so nothing is sent yet.
    //
    // Committing the profile here is what made step two a one-way door: the
    // backend refuses a second `PUT /onboarding/profile` with "Profil sudah
    // lengkap", so a user who walked back to fix a typo could no longer save
    // it. Banking the draft instead keeps both steps editable until the
    // registration form submits them together.
    //
    // Pushed, not `go`: the profile screen has to stay underneath for "Kembali"
    // to return to it. Nothing redirects it away — the global redirect only
    // fires when an invite token is banked, and this branch is the one where
    // there is none.
    if (!isInvite && _startsNewRegistration) {
      notifier.saveProfileDraft(request);
      context.push(_registerBankSampahRoute);
      return;
    }

    // Same deferral, for the nasabah wizard: the bank-sampah picker submits
    // this draft alongside the membership application, so the user can still
    // come back and edit their profile (including the alamat just entered)
    // right up until that final submit.
    if (!isInvite && _startsNasabahRegistration) {
      notifier.saveProfileDraft(request);
      context.push('/register-nasabah');
      return;
    }

    setState(() => _isLoading = true);

    final (:result, :error) = await notifier.completeProfile(request);

    if (!mounted) return;

    if (error != null) {
      setState(() => _isLoading = false);
      _showError(error.displayMessage);
      return;
    }

    if (isInvite) {
      await _joinInvitingBankSampah(profileNextStep: result?.nextStep);
      return;
    }

    setState(() => _isLoading = false);

    // The name (and gender/dob) were just saved server-side; refresh the cached
    // user so the dashboard/profile show the entered name, not the Google one.
    ref.read(authenticationProvider.notifier).refreshUser();

    _routeByNextStep(result?.nextStep, isInvite: false);
  }

  /// Redeems the deep-link token now that the profile is saved.
  ///
  /// Accepting second is deliberate: the backend derives `next_step` from the
  /// profile being complete, so this order gives an accurate routing hint, and
  /// an invalid form can't consume the invite. The token came from the link
  /// that opened the app, so there is nothing to ask the user for.
  ///
  /// [profileNextStep] is where the user belongs on their own merits, used when
  /// the invite turns out to be unusable.
  Future<void> _joinInvitingBankSampah(
      {required String? profileNextStep}) async {
    final store = di<InviteTokenStore>();
    // Captured before the refresh below re-emits the session.
    final authState = ref.read(authenticationProvider);
    final bankSampahStatus = authState is Authenticated
        ? authState.authEntity.bankSampahStatus
        : null;

    final (:result, :error) = await ref
        .read(onboardingProvider.notifier)
        .acceptInvite(store.token ?? '');
    if (!mounted) return;

    final acceptance = classifyInviteAcceptance(result: result, error: error);

    // Only a verdict retires the token. A timeout or a dropped session says
    // nothing about the invite, and the profile is already saved, so the button
    // becomes a working retry without the link having to be tapped again.
    if (acceptance.isTerminal) store.clear();

    setState(() => _isLoading = false);

    ref.read(authenticationProvider.notifier).refreshUser();

    switch (acceptance) {
      case InviteAcceptance.joined:
      case InviteAcceptance.alreadyMember:
        // On the inviting bank sampah, which is active by the time an invite for
        // it exists — so onboarding ends here, at the dashboard, never at the
        // registration form the non-invite flow continues to.
        context.go(_dashboardRoute);
        break;
      case InviteAcceptance.otherBank:
      case InviteAcceptance.rejected:
        // The invite didn't apply, but the profile was still saved. Route by
        // what this account actually is: `rejected` may have no bank sampah at
        // all, and `otherBank`'s existing one may still be pending or rejected —
        // a hardcoded dashboard would 403 behind `IsActivePengelola`.
        _routeByNextStep(profileNextStep, isInvite: false);
        break;
      case InviteAcceptance.failed:
        // Nothing conclusive: stay on the form, entered data intact, so the
        // button can be pressed again.
        break;
    }

    showInviteAcceptanceNotice(
      acceptance,
      backendMessage: error?.displayMessage ?? '',
      // `profileNextStep` is the freshest verdict there is — it came back from
      // the profile save moments ago, so it already accounts for the account's
      // own bank sampah registration.
      registrationUnderReview: hasRegistrationUnderReview(
        step: profileNextStep,
        bankSampahStatus: bankSampahStatus,
      ),
      // Same source as the gate uses, so a new joiner and an existing one see
      // identical copy.
      bankSampahNama: result?.bankSampahNama,
    );
  }

  void _routeByNextStep(String? nextStep, {required bool isInvite}) {
    switch (nextStep) {
      case 'dashboard':
        context.go(_dashboardRoute);
        break;
      case 'register_bank_sampah':
        context.go(_registerBankSampahRoute);
        break;
      case 'approval_pending':
        context.go('/pending-approval');
        break;
      case 'superadmin_dashboard':
        context.go('/superadmin-dashboard');
        break;
      case 'register_nasabah':
        context.go('/register-nasabah');
        break;
      case 'nasabah_dashboard':
        context.go('/nasabah-dashboard');
        break;
      case 'register_bank_sampah_induk':
        context.go('/register-bank-sampah-induk');
        break;
      case 'pengelola_induk_dashboard':
        context.go('/pengelola-induk-dashboard');
        break;
      default:
        // Fallback preserves prior behaviour: invited managers join an existing
        // bank sampah (dashboard), new managers continue to registration.
        context.go(isInvite ? _dashboardRoute : _registerBankSampahRoute);
    }
  }

  void _showError(String message, {String title = 'Gagal'}) {
    AppNotification.showError(context, title: title, message: message);
  }

  /// Intercepts a back-navigation attempt. [canPop] on the [PopScope] is false,
  /// so the pop is already blocked when this fires; we only need to offer the
  /// exit confirmation.
  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    confirmExitOnboarding(context, title: 'Batal Lengkapi Profil?');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationProvider, (previous, current) {
      if (current is Unauthenticated) context.go(LoginPage.route);
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop),
      child: Scaffold(
        backgroundColor: AppColors.surface, // Light gray background
        body: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Header Section
              OnboardingHeader(
                title: 'Lengkapi Profil Anda',
                subtitle: 'Data ini digunakan untuk verifikasi akun Anda.',
                onExit: () => confirmExitOnboarding(context,
                    title: 'Batal Lengkapi Profil?'),
              ),

              // The stepper shows only when profile completion leads to the
              // bank sampah registration form, pengelola or nasabah.
              if (!_isInviteMode &&
                  (_startsNewRegistration || _startsNasabahRegistration))
                OnboardingStepper(
                  currentStep: 1,
                  secondStepLabel:
                      _isNasabah ? 'Pilih Bank Sampah' : 'Data Bank Sampah',
                ),

              const SizedBox(height: 24),
              OnboardingFormCard(
                formKey: _formKey,
                children: [
                  OnboardingNameField(
                    controller: _nameController,
                    label: 'NAMA LENGKAP',
                    hintText: 'Contoh: Siti Rahayu',
                  ),

                  // Field 2: Jenis Kelamin
                  OnboardingFormField(
                    label: 'JENIS KELAMIN',
                    child: DropdownButtonFormField<String>(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      initialValue: _gender,
                      hint: Text(
                        'Pilih jenis kelamin',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey),
                      items: const [
                        DropdownMenuItem(
                          value: _genderMaleLabel,
                          child: Row(
                            children: [
                              Icon(Icons.male,
                                  size: 20, color: AppColors.inkSoft),
                              SizedBox(width: 8),
                              Text(_genderMaleLabel),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Perempuan',
                          child: Row(
                            children: [
                              Icon(Icons.female,
                                  size: 20, color: AppColors.inkSoft),
                              SizedBox(width: 8),
                              Text('Perempuan'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _gender = val;
                        });
                      },
                      decoration: appInputDecoration(),
                      validator: (value) {
                        if (value == null) {
                          return 'Jenis kelamin wajib dipilih';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Field 3: Tanggal Lahir
                  OnboardingFormField(
                    label: 'TANGGAL LAHIR',
                    child: TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _selectDate,
                      decoration: appInputDecoration(
                          hintText: 'dd/mm/yyyy',
                          suffixIcon: const Icon(Icons.calendar_today_outlined,
                              color: Colors.black87)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tanggal lahir wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ),

                  OnboardingPhoneField(
                    controller: _phoneController,
                    label: 'NOMOR HP / WHATSAPP',
                    requiredMessage: 'Nomor HP wajib diisi',
                  ),

                  // Alamat: nasabah accounts only.
                  if (_isNasabah)
                    OnboardingAddressField(controller: _alamatController),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AppButton(
                  label: _isInviteMode
                      ? 'Simpan & Masuk Dashboard'
                      : 'Simpan Profil & Lanjut',
                  trailingIcon: Icons.arrow_forward,
                  isLoading: _isLoading,
                  onPressed: _onSaveAndContinue,
                ),
              ),

              // 5. Footer Text
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Data Anda aman dan hanya digunakan untuk keperluan verifikasi bank sampah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
