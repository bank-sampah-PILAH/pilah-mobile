import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/design/widgets/phone_prefix.dart';

/// The parts that the add and the edit sheet of a nasabah have in common.
///
/// The two sheets keep their own state, validation of the ID and submit
/// logic, because those differ: only what a field looks like and the checks
/// that are the same everywhere live here.

const _wajibDiisi = 'Bagian ini wajib diisi.';

/// The sheet around the form of a nasabah: [title], a line about WhatsApp, an
/// optional [notice], the [fields] and the save [button].
class NasabahFormSheet extends StatelessWidget {
  const NasabahFormSheet({
    super.key,
    required this.title,
    required this.formKey,
    required this.fields,
    required this.button,
    this.notice,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final Widget button;
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BottomSheetHeader(title: title),
            const SizedBox(height: 12),
            Text(
              'Pastikan nomor WhatsApp aktif untuk menerima notifikasi '
              'transaksi.',
              style: AppTextStyle.small.copyWith(
                color: AppColors.grey100,
                height: 1.4,
              ),
            ),
            if (notice != null) ...[const SizedBox(height: 16), notice!],
            const SizedBox(height: 24),
            ...fields,
            const SizedBox(height: 32),
            button,
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// A field with its capital caption above it and, unless [spaced] is false,
/// the gap that separates it from the next field.
class NasabahFormField extends StatelessWidget {
  const NasabahFormField({
    super.key,
    required this.label,
    required this.child,
    this.spaced = true,
  });

  final String label;
  final Widget child;
  final bool spaced;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(label),
        const SizedBox(height: 8),
        child,
        if (spaced) const SizedBox(height: 20),
      ],
    );
  }
}

/// Two fields side by side, such as the ID and the gender.
class NasabahFieldPair extends StatelessWidget {
  const NasabahFieldPair({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class NasabahNameField extends StatelessWidget {
  const NasabahNameField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return NasabahFormField(
      label: 'NAMA LENGKAP',
      child: TextFormField(
        controller: controller,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? _wajibDiisi : null,
        decoration: appInputDecoration(hintText: 'Contoh: Budi Santoso'),
      ),
    );
  }
}

/// The ID of a nasabah. What makes an ID valid differs between adding and
/// editing, so the sheet passes its own [validator]; [onChanged] lets it clear
/// an error as the user types, and [hasError] paints the border red when the
/// message is shown elsewhere.
class NasabahIdField extends StatelessWidget {
  const NasabahIdField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.validator,
    this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String hintText;
  final FormFieldValidator<String> validator;
  final VoidCallback? onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return NasabahFormField(
      label: 'ID NASABAH',
      spaced: false,
      child: TextFormField(
        controller: controller,
        onChanged: (_) => onChanged?.call(),
        validator: validator,
        decoration: appInputDecoration(hintText: hintText, hasError: hasError),
      ),
    );
  }
}

class NasabahGenderField extends StatelessWidget {
  const NasabahGenderField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return NasabahFormField(
      label: 'JENIS KELAMIN',
      spaced: false,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Pilih jenis kelamin.' : null,
        hint: const Text('— Pilih —'),
        decoration: appInputDecoration(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.grey100),
        items: const ['Laki-laki', 'Perempuan']
            .map((jenis) => DropdownMenuItem(value: jenis, child: Text(jenis)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// The Google email of a nasabah, which links the record to their account
/// when they sign in later. [serverError] returns what the backend said about
/// it, shown until [onChanged] clears it. It is a getter rather than a value
/// because the sheet sets the error and validates in the same frame, before
/// this field is rebuilt.
class NasabahEmailField extends StatelessWidget {
  const NasabahEmailField({
    super.key,
    required this.controller,
    this.serverError,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueGetter<String?>? serverError;
  final VoidCallback? onChanged;
  final bool enabled;

  static final _format = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Widget build(BuildContext context) {
    return NasabahFormField(
      label: 'EMAIL',
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.emailAddress,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (_) => onChanged?.call(),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Email wajib diisi.';
          }
          if (!_format.hasMatch(value.trim())) {
            return 'Format email tidak valid.';
          }
          return serverError?.call();
        },
        decoration: appInputDecoration(hintText: 'Contoh: budi@gmail.com'),
      ),
    );
  }
}

/// The date of birth, picked with [onTap] rather than typed.
class NasabahBirthDateField extends StatelessWidget {
  const NasabahBirthDateField({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NasabahFormField(
      label: 'TANGGAL LAHIR',
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? _wajibDiisi : null,
        decoration: appInputDecoration(
          hintText: 'dd/mm/yyyy',
          suffixIcon: const Icon(
            Icons.calendar_today,
            color: AppColors.grey100,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// The WhatsApp number typed after "+62". [serverError] returns what the
/// backend said about it, shown until [onChanged] clears it (a getter, see
/// [NasabahEmailField]).
class NasabahPhoneField extends StatelessWidget {
  const NasabahPhoneField({
    super.key,
    required this.controller,
    this.serverError,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueGetter<String?>? serverError;
  final VoidCallback? onChanged;

  static final _format = RegExp(r'^8[1-9][0-9]{7,11}$');

  @override
  Widget build(BuildContext context) {
    return NasabahFormField(
      label: 'NOMOR WHATSAPP',
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => onChanged?.call(),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Nomor WhatsApp wajib diisi.';
          }
          if (!_format.hasMatch(value)) {
            return 'Format nomor tidak valid. Mulai dengan angka 8';
          }
          return serverError?.call();
        },
        decoration: appInputDecoration(
          hintText: '812-3456-7890',
          prefixIcon: const PhonePrefix(),
        ),
      ),
    );
  }
}

/// The street address. The last field of the form, so no gap below it: the
/// sheet adds the space before its button.
class NasabahAddressField extends StatelessWidget {
  const NasabahAddressField({
    super.key,
    required this.controller,
    required this.validator,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return NasabahFormField(
      label: 'ALAMAT LENGKAP',
      spaced: false,
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        validator: validator,
        decoration: appInputDecoration(
          hintText: 'Nama jalan, RT/RW, Kelurahan...',
        ),
      ),
    );
  }
}
