import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
