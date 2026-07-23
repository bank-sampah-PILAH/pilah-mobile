import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/invite_acceptance.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/invite_acceptance_notice.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';

class CompleteProfileScreen extends StatefulWidget {
  final bool isInviteMode;

  const CompleteProfileScreen({super.key, this.isInviteMode = false});

  static const route = '/complete-profile';

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  /// Invite mode is whatever the store says, with the constructor flag as a
  /// hint on top.
  ///
  /// The store is asked directly rather than trusted to have been read at route
  /// build time: this screen is also reached by routes that never set the flag
  /// (a login that resolves to `complete_profile`, a re-entry after logout), and
  /// on those the two-step stepper used to reappear for a user who is joining an
  /// existing bank sampah and will never see step 2.
  bool get _isInviteMode => widget.isInviteMode || di<InviteTokenStore>().hasToken;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _gender;
  DateTime? _selectedDob;
  bool _isLoading = false;

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
  /// Reads straight from the cubit rather than waiting for a state emission:
  /// the draft is not part of [OnboardingState], and the controllers have to be
  /// populated before the first build or the fields flash empty.
  void _restoreDraft() {
    final draft = context.read<OnboardingCubit>().profileDraft;
    if (draft == null) return;

    _nameController.text = draft.nama;
    _phoneController.text = draft.noHp;
    _gender = draft.jenisKelamin == 'laki-laki' ? 'Laki-laki' : 'Perempuan';

    // Stored as the ISO string the API wants; the picker and the field need a
    // DateTime and dd/MM/yyyy back.
    final parsed = DateTime.tryParse(draft.tanggalLahir);
    if (parsed != null) {
      _selectedDob = parsed;
      _dobController.text = _displayDate(parsed);
    }
  }

  String _displayDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  @override
  void dispose() {
    di<InviteTokenStore>().removeListener(_onInviteTokenChanged);
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.greenDark, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
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
    final authState = context.read<AuthenticationBloc>().state;
    if (authState is! Authenticated) return false;
    return authState.authEntity.bankSampahStatus == null;
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
      jenisKelamin: _gender == 'Laki-laki' ? 'laki-laki' : 'perempuan',
      tanggalLahir: _selectedDob != null ? _isoDate(_selectedDob!) : '',
      noHp: _phoneController.text.trim(),
    );

    final cubit = context.read<OnboardingCubit>();

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
      cubit.saveProfileDraft(request);
      context.push('/register-bank-sampah');
      return;
    }

    setState(() => _isLoading = true);

    final (:result, :error) = await cubit.completeProfile(request);

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
    context.read<AuthenticationBloc>().add(RefreshUserRequested());

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
  Future<void> _joinInvitingBankSampah({required String? profileNextStep}) async {
    final store = di<InviteTokenStore>();
    // Captured before the refresh below re-emits the session.
    final authState = context.read<AuthenticationBloc>().state;
    final bankSampahStatus =
        authState is Authenticated ? authState.authEntity.bankSampahStatus : null;

    final (:result, :error) =
        await context.read<OnboardingCubit>().acceptInvite(store.token ?? '');
    if (!mounted) return;

    final acceptance = classifyInviteAcceptance(result: result, error: error);

    // Only a verdict retires the token. A timeout or a dropped session says
    // nothing about the invite, and the profile is already saved, so the button
    // becomes a working retry without the link having to be tapped again.
    if (acceptance.isTerminal) store.clear();

    setState(() => _isLoading = false);

    context.read<AuthenticationBloc>().add(RefreshUserRequested());

    switch (acceptance) {
      case InviteAcceptance.joined:
      case InviteAcceptance.alreadyMember:
        // On the inviting bank sampah, which is active by the time an invite for
        // it exists — so onboarding ends here, at the dashboard, never at the
        // registration form the non-invite flow continues to.
        context.go('/dashboard');
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
        context.go('/dashboard');
        break;
      case 'register_bank_sampah':
        context.go('/register-bank-sampah');
        break;
      case 'approval_pending':
        context.go('/pending-approval');
        break;
      case 'superadmin_dashboard':
        context.go('/superadmin-dashboard');
        break;
      default:
        // Fallback preserves prior behaviour: invited managers join an existing
        // bank sampah (dashboard), new managers continue to registration.
        context.go(isInvite ? '/dashboard' : '/register-bank-sampah');
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
    _confirmExit();
  }

  /// Shows the "leave onboarding" confirmation. On confirm, runs the standard
  /// logout (clears the session and emits [Unauthenticated]); the [BlocListener]
  /// in [build] handles the redirect to login. Cancelling or dismissing leaves
  /// the form and its input untouched.
  Future<void> _confirmExit() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Batal Lengkapi Profil?',
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
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
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
          backgroundColor: const Color(0xFFF9FAFB), // Light gray background
          body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 70, left: 24, right: 24, bottom: 40),
              decoration: const BoxDecoration(
                color: AppColors.greenDark,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lengkapi Profil Anda',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data ini digunakan untuk verifikasi akun Anda.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
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

            // 2. Stepper Section (hidden in invite mode)
            if (!_isInviteMode) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Step 1
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
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

                    // Connector Line
                    Container(
                      width: 100,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      color: Colors.grey.shade300,
                    ),

                    // Step 2
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data Bank Sampah',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 3. Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
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
                      // Field 1: Nama Lengkap
                      _buildFormField(
                        label: 'NAMA LENGKAP',
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Siti Rahayu',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.normal,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.greenDark, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'Nama minimal 3 karakter';
                            }
                            return null;
                          },
                        ),
                      ),

                      // Field 2: Jenis Kelamin
                      _buildFormField(
                        label: 'JENIS KELAMIN',
                        child: DropdownButtonFormField<String>(
                          value: _gender,
                          hint: Text(
                            'Pilih jenis kelamin',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          items: const [
                            DropdownMenuItem(
                              value: 'Laki-laki',
                              child: Row(
                                children: [
                                  Icon(Icons.male, size: 20, color: Color(0xFF2563EB)),
                                  SizedBox(width: 8),
                                  Text('Laki-laki'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Perempuan',
                              child: Row(
                                children: [
                                  Icon(Icons.female, size: 20, color: Color(0xFFDB2777)),
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
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.greenDark, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Jenis kelamin wajib dipilih';
                            }
                            return null;
                          },
                        ),
                      ),

                      // Field 3: Tanggal Lahir
                      _buildFormField(
                        label: 'TANGGAL LAHIR',
                        child: TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          onTap: _selectDate,
                          decoration: InputDecoration(
                            hintText: 'dd/mm/yyyy',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.normal,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.greenDark, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            suffixIcon:
                                const Icon(Icons.calendar_today_outlined, color: Colors.black87),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Tanggal lahir wajib diisi';
                            }
                            return null;
                          },
                        ),
                      ),

                      // Field 4: Nomor HP
                      _buildFormField(
                        label: 'NOMOR HP / WHATSAPP',
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '812-3456-7890',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.normal,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+62',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 24,
                                    width: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                ],
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.greenDark, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 16),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nomor HP wajib diisi';
                            }
                            final regex = RegExp(r'^8[1-9][0-9]{7,11}$');
                            if (!regex.hasMatch(value)) {
                              return 'Format nomor tidak valid.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // 4. Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSaveAndContinue,
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
                              _isInviteMode ? 'Simpan & Masuk Dashboard' : 'Simpan Profil & Lanjut',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                ),
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
      ),
    );
  }
}
