import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/phone_prefix.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/logout_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';

class RegisterBankSampahScreen extends StatefulWidget {
  /// True when the user is re-applying after a previous registration was
  /// rejected. Swaps the onboarding stepper for a rejection notice; the form
  /// itself is identical to a first-time registration.
  final bool isRejectedReapplication;

  const RegisterBankSampahScreen({
    super.key,
    this.isRejectedReapplication = false,
  });

  static const route = '/register-bank-sampah';

  @override
  State<RegisterBankSampahScreen> createState() =>
      _RegisterBankSampahScreenState();
}

class _RegisterBankSampahScreenState extends State<RegisterBankSampahScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    // Covers the photo too: it is a FormField, so a missing one fails here and
    // is reported inline on the picker, exactly like the text fields. No
    // separate notification — that is what made the photo feel different.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final image = _selectedImage;
    final bytes = _selectedImageBytes;
    if (image == null || bytes == null) return;

    setState(() => _isLoading = true);

    final request = RegisterBankSampahRequest(
      nama: _namaController.text.trim(),
      alamat: _alamatController.text.trim(),
      noHpPic: _phoneController.text.trim(),
      fotoKegiatanBytes: bytes,
      fotoKegiatanFilename: image.name,
    );

    // Sends the banked profile first when the user came through step one, and
    // only the registration otherwise. Either way a failure leaves them here
    // with the form intact, and the profile half is not re-sent on retry.
    final (:result, :error) =
        await context.read<OnboardingCubit>().submitRegistration(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error.displayMessage);
      return;
    }

    // Bank sampah now linked to the user; refresh the cached session so the
    // header reflects the new bank name.
    context.read<AuthenticationBloc>().add(RefreshUserRequested());

    // Registration submitted → backend sets status to pending review.
    if (result?.nextStep == 'dashboard') {
      context.go('/dashboard');
    } else {
      context.go('/pending-approval');
    }
  }

  void _showError(String message) {
    AppNotification.showError(context, title: 'Gagal', message: message);
  }

  /// Picks the activity photo and reports it to [field], so the inline error
  /// clears the moment a photo is chosen rather than lingering until the next
  /// submit.
  Future<void> _pickImage(FormFieldState<XFile> field) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
      field.didChange(image);
    } catch (_) {
      if (mounted) _showError('Foto tidak dapat dibaca. Silakan coba lagi.');
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
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  /// The notice shown at the top of the form when re-applying after a rejection.
  /// The backend does not surface a rejection reason to the pengelola, so the
  /// copy is the fixed guidance text.
  Widget _buildRejectionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerLight, // red-50
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.dangerLight), // red-200
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendaftaran Ditolak',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pendaftaran sebelumnya ditolak. Mohon periksa kembali data '
                  'Anda dan daftar ulang.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Whether this form is step two of the wizard rather than a destination in
  /// its own right.
  ///
  /// A banked draft is the evidence: it exists only when the profile screen
  /// pushed this route and is still sitting underneath, which is also the only
  /// case where popping leads anywhere useful. Reached any other way — a
  /// redirect after login, a rejected re-application — there is no page behind
  /// this one and back has to keep meaning "leave onboarding".
  bool get _isWizardStep => context.read<OnboardingCubit>().hasProfileDraft;

  /// Intercepts a back-navigation attempt.
  ///
  /// Mid-wizard the pop is allowed through to the profile screen, which refills
  /// itself from the draft. Offering to log them out instead — which is what
  /// this did unconditionally — would throw away a completed form to answer a
  /// request to edit it.
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
  ///
  /// Falls back to `go` for the case the draft outlived the stack — a warm
  /// start that restored straight onto this route, say — where there is nothing
  /// to pop and the profile screen has to be navigated to outright. It refills
  /// from the draft either way.
  void _backToProfile() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      context.go('/complete-profile');
    }
  }

  /// Shows the "leave registration" confirmation. On confirm, runs the standard
  /// logout (clears the session and emits [Unauthenticated]); the [BlocListener]
  /// in [build] handles the redirect to login. Cancelling or dismissing leaves
  /// the form and its input untouched.
  Future<void> _confirmExit() async {
    final shouldLogout = await showAppConfirmDialog(
      context,
      title: 'Keluar dari Pendaftaran?',
      message:
          'Apakah Anda yakin ingin keluar? Progress pengisian data Anda belum '
          'tersimpan dan Anda akan dialihkan ke halaman login.',
      confirmLabel: 'Ya, Keluar',
      destructive: true,
    );
    if (shouldLogout && mounted) {
      context.read<AuthenticationBloc>().add(LogoutRequested());
    }
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
          backgroundColor: AppColors.surface,
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
                              'Daftarkan Bank Sampah',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lengkapi data institusi bank sampah Anda.',
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

                // Rejection notice — shown in place of the onboarding stepper when
                // the user is re-applying after a rejected registration.
                if (widget.isRejectedReapplication) _buildRejectionBanner(),

                // 2. Stepper Section — first-time onboarding only.
                if (!widget.isRejectedReapplication)
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

                        // Connector Line
                        Container(
                          width: 100,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          color: AppColors.greenDark,
                        ),

                        // Step 2
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
                              'Data Bank Sampah',
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

                // 3. Form Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
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
                          // Field 1: Nama Bank Sampah
                          _buildFormField(
                            label: 'NAMA BANK SAMPAH',
                            child: TextFormField(
                              controller: _namaController,
                              decoration: appInputDecoration(
                                  hintText: 'Contoh: Bank Sampah Mekar Jaya'),
                              validator: (value) {
                                if (value == null || value.trim().length < 3) {
                                  return 'Nama minimal 3 karakter';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Field 2: Alamat Lengkap
                          _buildFormField(
                            label: 'ALAMAT LENGKAP',
                            child: TextFormField(
                              controller: _alamatController,
                              maxLines: 5,
                              minLines: 3,
                              decoration: appInputDecoration(
                                  hintText:
                                      'Jl. Nama Jalan, RT/RW, Kelurahan,\nKecamatan, Kota'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Alamat wajib diisi';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Field 3: Nomor Telepon
                          _buildFormField(
                            label: 'NOMOR TELEPON PENANGGUNG JAWAB',
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: appInputDecoration(
                                  hintText: '812-3456-7890',
                                  prefixIcon: const PhonePrefix()),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nomor Telepon wajib diisi';
                                }
                                final regex = RegExp(r'^8[1-9][0-9]{7,11}$');
                                if (!regex.hasMatch(value)) {
                                  return 'Format nomor tidak valid.';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Field 4: Foto Kegiatan
                          //
                          // A FormField rather than a bare picker so the photo is
                          // validated by _formKey.currentState.validate() alongside
                          // the text fields. Submitting an empty form therefore
                          // turns this box red and prints its own inline error, the
                          // same as every other required field, instead of the
                          // photo alone failing via a separate notification.
                          _buildFormField(
                            label: 'FOTO KEGIATAN',
                            description:
                                'Upload foto kegiatan penimbangan sampah yang valid',
                            child: FormField<XFile>(
                              initialValue: _selectedImage,
                              // Without this the validator only re-runs on the next
                              // submit, so the box would stay red even after the
                              // user picked a photo. onUserInteraction keeps it
                              // quiet until they touch the field, then clears the
                              // error the moment they fix it.
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (file) => file == null
                                  ? 'Foto kegiatan wajib diunggah'
                                  : null,
                              builder: (field) {
                                // The same colour Material gives a TextFormField's
                                // error, so the two read as one form.
                                final errorColor =
                                    Theme.of(field.context).colorScheme.error;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () => _pickImage(field),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      child: _selectedImage != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.md),
                                              child: Stack(
                                                children: [
                                                  Image.memory(
                                                    _selectedImageBytes!,
                                                    width: double.infinity,
                                                    height: 150,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: AppTapTarget(
                                                      label: 'Hapus foto',
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              AppRadius.xl),
                                                      onTap: () {
                                                        setState(() {
                                                          _selectedImage = null;
                                                          _selectedImageBytes =
                                                              null;
                                                        });
                                                        field.didChange(null);
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : CustomPaint(
                                              painter: _DashedRectPainter(
                                                  color: field.hasError
                                                      ? errorColor
                                                      : Colors.grey.shade400,
                                                  strokeWidth: 1.5,
                                                  gap: 5.0,
                                                  radius: 12.0),
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 32),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.image_outlined,
                                                        color:
                                                            AppColors.greenDark,
                                                        size: 32),
                                                    const SizedBox(height: 12),
                                                    const Text(
                                                      'Pilih foto',
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'JPG / PNG · Maks. 5 MB',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade500,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                    if (field.hasError) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        field.errorText!,
                                        style: TextStyle(
                                          color: errorColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      AppButton(
                        label: 'Ajukan Pendaftaran',
                        trailingIcon: Icons.arrow_forward,
                        isLoading: _isLoading,
                        onPressed: _onSubmit,
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Kembali',
                        variant: AppButtonVariant.neutral,
                        onPressed: _backToProfile,
                      ),
                    ],
                  ),
                ),

                // 5. Footer Text
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Pengajuan akan ditinjau oleh Admin PILAH.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
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

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius)));

    Path dashPath = Path();

    double dashWidth = gap;
    double dashSpace = gap;
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, dashedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
