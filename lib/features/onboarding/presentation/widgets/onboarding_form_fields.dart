import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/widgets/phone_prefix.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_layout.dart';

/// The sticky submit can be tapped from anywhere in the form. Reveal the first
/// invalid field rather than leaving its error outside the viewport.
bool validateOnboardingForm(GlobalKey<FormState> formKey) {
  final errors = formKey.currentState?.validateGranularly();
  if (errors == null) return false;
  if (errors.isEmpty) return true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final field = errors.first;
    if (field.mounted) Scrollable.ensureVisible(field.context, alignment: 0.1);
  });
  return false;
}

/// A name of a person or of a bank sampah, at least three characters.
class OnboardingNameField extends StatelessWidget {
  const OnboardingNameField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return OnboardingFormField(
      label: label,
      child: TextFormField(
        controller: controller,
        decoration: appInputDecoration(hintText: hintText),
        validator: (value) {
          if (value == null || value.trim().length < 3) {
            return 'Nama minimal 3 karakter';
          }
          return null;
        },
      ),
    );
  }
}

/// A mobile number typed after the "+62" prefix: digits only, starting with 8.
/// [requiredMessage] is what an empty field says, such as "Nomor HP wajib
/// diisi".
class OnboardingPhoneField extends StatelessWidget {
  const OnboardingPhoneField({
    super.key,
    required this.controller,
    required this.label,
    required this.requiredMessage,
  });

  final TextEditingController controller;
  final String label;
  final String requiredMessage;

  static final _format = RegExp(r'^8[1-9][0-9]{7,11}$');

  @override
  Widget build(BuildContext context) {
    return OnboardingFormField(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        decoration: appInputDecoration(
          hintText: '812-3456-7890',
          prefixIcon: const PhonePrefix(),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.trim().isEmpty) return requiredMessage;
          if (!_format.hasMatch(value)) return 'Format nomor tidak valid.';
          return null;
        },
      ),
    );
  }
}

/// A full street address in a few lines.
class OnboardingAddressField extends StatelessWidget {
  const OnboardingAddressField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return OnboardingFormField(
      label: 'ALAMAT LENGKAP',
      child: TextFormField(
        controller: controller,
        maxLines: 5,
        minLines: 3,
        decoration: appInputDecoration(
          hintText: 'Jl. Nama Jalan, RT/RW, Kelurahan,\nKecamatan, Kota',
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Alamat wajib diisi';
          }
          return null;
        },
      ),
    );
  }
}

/// A birth date picked from a calendar, optional for a nasabah (PIL-478).
///
/// The box is [readOnly] so the picker is the only way a date gets in. That
/// makes the clear button the only way one gets back out, which is why it
/// exists at all rather than being left to a long-press or a select-all.
///
/// [isOptional] drives the whole field at once: the star on the label, the
/// "(opsional)" hint, whether a clear button is offered, and whether an empty
/// value validates. Keeping them on one flag is deliberate — a pengelola is
/// still required to give a birth date, because `is_profile_complete` gates
/// their bank registration on it server-side, and a form that let them skip
/// it would fail later and less clearly.
class OnboardingBirthDateField extends StatelessWidget {
  const OnboardingBirthDateField({
    super.key,
    required this.controller,
    required this.onTap,
    required this.isOptional,
    this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onTap;
  final bool isOptional;

  /// Empties the field. Only ever offered while [isOptional].
  final VoidCallback? onClear;

  /// What is wrong with [value], or null when it is fine. Static so the
  /// screen's own tests can state the rule without pumping a widget.
  static String? errorFor(String? value, {required bool isOptional}) {
    if (isOptional) return null;
    if (value == null || value.isEmpty) return 'Tanggal lahir wajib diisi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final offersClear = isOptional && onClear != null;
    return OnboardingFormField(
      label: 'TANGGAL LAHIR',
      isRequired: !isOptional,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: appInputDecoration(
            hintText: isOptional ? 'dd/mm/yyyy (opsional)' : 'dd/mm/yyyy',
            suffixIcon: (offersClear && value.text.trim().isNotEmpty)
                ? IconButton(
                    tooltip: 'Hapus tanggal lahir',
                    onPressed: onClear,
                    icon: const Icon(Icons.close, color: AppColors.black),
                  )
                : const Icon(Icons.calendar_today_outlined,
                    color: AppColors.black),
          ),
          validator: (value) => errorFor(value, isOptional: isOptional),
        ),
      ),
    );
  }
}
