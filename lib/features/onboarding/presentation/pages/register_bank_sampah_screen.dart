import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_flow_layout.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_layout.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_exit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_form_fields.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_step_scaffold.dart';

class RegisterBankSampahScreen extends ConsumerStatefulWidget {
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
  ConsumerState<RegisterBankSampahScreen> createState() =>
      _RegisterBankSampahScreenState();
}

class _RegisterBankSampahScreenState
    extends ConsumerState<RegisterBankSampahScreen> {
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
    if (!validateOnboardingForm(_formKey)) return;

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
        await ref.read(onboardingProvider.notifier).submitRegistration(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error.displayMessage);
      return;
    }

    // Bank sampah now linked to the user; refresh the cached session so the
    // header reflects the new bank name.
    ref.read(authenticationProvider.notifier).refreshUser();

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

  /// The notice shown at the top of the form when re-applying after a rejection.
  /// The backend does not surface a rejection reason to the pengelola, so the
  /// copy is the fixed guidance text.
  Widget _buildRejectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerLight, // red-50
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.dangerLight), // red-200
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendaftaran Ditolak',
                  style:
                      AppTextStyle.headline3.copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pendaftaran sebelumnya ditolak. Mohon periksa kembali data '
                  'Anda dan daftar ulang.',
                  style: AppTextStyle.small.copyWith(color: AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Daftarkan Bank Sampah',
      subtitle:
          'Lengkapi informasi bank sampah dan unggah foto kegiatan untuk ditinjau Admin PILAH.',
      onExit: () => confirmExitOnboarding(context),
      onUnauthenticated: () => context.go(LoginPage.route),
      progress: widget.isRejectedReapplication
          ? const SizedBox.shrink()
          : const OnboardingProgress(currentStep: 2),
      notice: widget.isRejectedReapplication ? _buildRejectionBanner() : null,
      formKey: _formKey,
      formFields: [
        Text('Informasi bank sampah', style: AppTextStyle.title1),
        const SizedBox(height: 8),
        Text('Semua kolom bertanda * wajib diisi.',
            style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
        const SizedBox(height: 24),
        OnboardingFieldPair(
          first:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            OnboardingNameField(
              controller: _namaController,
              label: 'NAMA BANK SAMPAH',
              hintText: 'Contoh: Bank Sampah Mekar Jaya',
            ),
            OnboardingAddressField(controller: _alamatController),
            OnboardingPhoneField(
              controller: _phoneController,
              label: 'NOMOR TELEPON PENANGGUNG JAWAB',
              requiredMessage: 'Nomor Telepon wajib diisi',
            ),
          ]),
          // Field 4: Foto Kegiatan
          //
          // A FormField rather than a bare picker so the photo is
          // validated by _formKey.currentState.validate() alongside
          // the text fields. Submitting an empty form therefore
          // turns this box red and prints its own inline error, the
          // same as every other required field, instead of the
          // photo alone failing via a separate notification.
          second: OnboardingFormField(
            label: 'FOTO KEGIATAN',
            description: 'Upload foto kegiatan penimbangan sampah yang valid',
            child: FormField<XFile>(
              initialValue: _selectedImage,
              // Without this the validator only re-runs on the next
              // submit, so the box would stay red even after the
              // user picked a photo. onUserInteraction keeps it
              // quiet until they touch the field, then clears the
              // error the moment they fix it.
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (file) =>
                  file == null ? 'Foto kegiatan wajib diunggah' : null,
              builder: (field) {
                // The same colour Material gives a TextFormField's
                // error, so the two read as one form.
                final errorColor = Theme.of(field.context).colorScheme.error;
                final placeholderColor =
                    field.hasError ? errorColor : AppColors.grey100;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _pickImage(field),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.md),
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
                                          BorderRadius.circular(AppRadius.xl),
                                      onTap: () {
                                        setState(() {
                                          _selectedImage = null;
                                          _selectedImageBytes = null;
                                        });
                                        field.didChange(null);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
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
                                  color: placeholderColor,
                                  strokeWidth: 1.5,
                                  gap: 5.0,
                                  radius: 12.0),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image_outlined,
                                        color: AppColors.greenDark, size: 32),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Pilih foto',
                                      style: TextStyle(
                                        color: AppColors.inkSoft,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'JPG / PNG · Maks. 5 MB',
                                      style: AppTextStyle.small
                                          .copyWith(color: AppColors.grey100),
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
        ),
        Text('Pengajuan akan ditinjau oleh Admin PILAH.',
            style: AppTextStyle.small.copyWith(color: AppColors.grey100)),
      ],
      footer: const [],
      actions: OnboardingActions(
        secondary: AppButton(
          label: 'Kembali',
          variant: AppButtonVariant.neutral,
          onPressed: _isLoading
              ? null
              : () => handleOnboardingStepPop(
                    context,
                    didPop: false,
                    isWizardStep: true,
                  ),
        ),
        primary: AppButton(
          label: 'Ajukan Pendaftaran',
          trailingIcon: Icons.arrow_forward,
          isLoading: _isLoading,
          onPressed: _onSubmit,
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
