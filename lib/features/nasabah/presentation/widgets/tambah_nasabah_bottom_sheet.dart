import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_form_fields.dart';

class TambahNasabahBottomSheet extends ConsumerStatefulWidget {
  const TambahNasabahBottomSheet({super.key});

  @override
  ConsumerState<TambahNasabahBottomSheet> createState() =>
      _TambahNasabahBottomSheetState();
}

/// Field keys the backend may report a duplicate-phone validation error under.
/// The live API uses `no_hp`; the others are accepted defensively so a rename
/// on the backend degrades to a still-inline error rather than a global one.
const _phoneErrorKeys = ['no_hp', 'no_whatsapp', 'phone'];

class _TambahNasabahBottomSheetState
    extends ConsumerState<TambahNasabahBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _idNasabahController = TextEditingController();
  final _emailController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _alamatController = TextEditingController();

  String? _jenisKelamin;
  bool _isSaving = false;
  // Duplicate-ID errors are surfaced via a full-width AppNotification: the ID
  // field is half-width, so inline errorText truncates to "...". This flag only
  // drives a red border on the field; the message itself lives in the toast.
  bool _kodeHasError = false;
  String? _serverPhoneError;
  String? _serverEmailError;

  @override
  void dispose() {
    _namaController.dispose();
    _idNasabahController.dispose();
    _emailController.dispose();
    _tanggalLahirController.dispose();
    _whatsappController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() =>
      pickNasabahBirthDate(context, _tanggalLahirController);

  @override
  Widget build(BuildContext context) {
    return NasabahFormSheet(
      title: 'Tambah Nasabah',
      formKey: _formKey,
      fields: [
        NasabahNameField(controller: _namaController),
        NasabahFieldPair(
          left: NasabahIdField(
            controller: _idNasabahController,
            hintText: 'NAS-0900',
            hasError: _kodeHasError,
            // Clear the red border as soon as the ID is edited.
            onChanged: () {
              if (_kodeHasError) setState(() => _kodeHasError = false);
            },
            // Only the required check stays inline (short, standard across the
            // form). The uniqueness check moved to submit (_handleSimpan) so
            // its longer message shows in full via AppNotification instead of
            // truncating in this narrow field.
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Bagian ini wajib diisi.'
                : null,
          ),
          right: NasabahGenderField(
            value: _jenisKelamin,
            onChanged: (jenis) => setState(() => _jenisKelamin = jenis),
          ),
        ),
        // The Google account email, used to sync the nasabah record when they
        // log in later (PIL-154).
        NasabahEmailField(
          controller: _emailController,
          serverError: () => _serverEmailError,
          // Clear the backend duplicate error as soon as the email is edited,
          // mirroring the phone field.
          onChanged: () {
            if (_serverEmailError != null) {
              setState(() => _serverEmailError = null);
            }
          },
        ),
        NasabahBirthDateField(
          controller: _tanggalLahirController,
          onTap: _selectDate,
        ),
        NasabahPhoneField(
          controller: _whatsappController,
          serverError: () => _serverPhoneError,
          // Clear the backend duplicate error as soon as the number is edited,
          // so the inline red text disappears while typing.
          onChanged: () {
            if (_serverPhoneError != null) {
              setState(() => _serverPhoneError = null);
            }
          },
        ),
        NasabahAddressField(
          controller: _alamatController,
          validator: (value) {
            final alamat = value?.trim() ?? '';
            if (alamat.isEmpty) return 'Bagian ini wajib diisi.';
            if (alamat.runes.length < 10) {
              return 'Alamat minimal 10 karakter.';
            }
            return null;
          },
        ),
      ],
      button: AppButton(
        label: 'Simpan Nasabah',
        isLoading: _isSaving,
        onPressed: _handleSimpan,
      ),
    );
  }

  Future<void> _handleSimpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(nasabahProvider.notifier);
    final state = ref.read(nasabahProvider);
    final kode = _idNasabahController.text.trim();

    // Uniqueness check, moved out of the inline validator: a duplicate ID gets a
    // full, readable message in a notification plus a red border on the field,
    // and still blocks the save.
    if (state is NasabahLoaded) {
      final list = state.nasabahList;
      final isDuplicate = list
          .any((e) => e.idNasabah.trim().toLowerCase() == kode.toLowerCase());
      if (isDuplicate) {
        setState(() => _kodeHasError = true);
        AppNotification.showError(
          context,
          title: 'ID Nasabah Sudah Digunakan',
          message:
              'ID Nasabah "$kode" sudah digunakan. Silakan gunakan ID lain.',
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    final request = NasabahRequest(
      kode: kode,
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      jenisKelamin: _jenisKelamin ?? 'Laki-laki',
      tanggalLahir: _tanggalLahirController.text.trim(),
      noHp: '+62${_whatsappController.text.trim()}',
      alamat: _alamatController.text.trim(),
    );

    final error = await notifier.addNasabah(request);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      context.pop();
      AppNotification.showSuccess(
        context,
        title: 'Berhasil',
        message: 'Nasabah baru berhasil ditambahkan.',
      );
      return;
    }

    // Backend validation (HTTP 422). The duplicate-ID (`kode`) error goes to a
    // notification with a red border — the field is too narrow for inline text.
    // The phone field is full-width, so its error stays inline and readable.
    // Anything we can't attribute to a field escalates to the global snackbar.
    final kodeError = error.fieldError(['kode']);
    final phoneError = error.fieldError(_phoneErrorKeys);
    final emailError = error.fieldError(['email']);

    if (kodeError != null) {
      setState(() => _kodeHasError = true);
      AppNotification.showError(
        context,
        title: 'ID Nasabah Sudah Digunakan',
        message: kodeError,
      );
      return;
    }

    if (emailError != null) {
      // Full-width field: inline error like the phone field.
      setState(() => _serverEmailError = emailError);
      _formKey.currentState?.validate();
      return;
    }

    if (phoneError != null) {
      setState(() => _serverPhoneError = phoneError);
      _formKey.currentState?.validate();
      return;
    }

    AppNotification.showError(
      context,
      title: 'Gagal Menyimpan',
      message: error.displayMessage,
    );
  }
}
