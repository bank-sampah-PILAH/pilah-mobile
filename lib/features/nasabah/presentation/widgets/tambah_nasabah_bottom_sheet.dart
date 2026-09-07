import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

class TambahNasabahBottomSheet extends StatefulWidget {
  const TambahNasabahBottomSheet({super.key});

  @override
  State<TambahNasabahBottomSheet> createState() =>
      _TambahNasabahBottomSheetState();
}

/// Field keys the backend may report a duplicate-phone validation error under.
/// The live API uses `no_hp`; the others are accepted defensively so a rename
/// on the backend degrades to a still-inline error rather than a global one.
const _phoneErrorKeys = ['no_hp', 'no_whatsapp', 'phone'];

class _TambahNasabahBottomSheetState extends State<TambahNasabahBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _idNasabahController = TextEditingController();
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

  @override
  void dispose() {
    _namaController.dispose();
    _idNasabahController.dispose();
    _tanggalLahirController.dispose();
    _whatsappController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        final day = picked.day.toString().padLeft(2, '0');
        final month = picked.month.toString().padLeft(2, '0');
        final year = picked.year.toString();
        _tanggalLahirController.text = '$day/$month/$year';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tambah Nasabah',
                      style: AppTextStyle.headline1.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.close,
                            color: Colors.grey[600], size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Pastikan nomor WhatsApp aktif untuk menerima notifikasi transaksi.',
                  style: AppTextStyle.small.copyWith(
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Field 1: NAMA LENGKAP
                _buildLabel('NAMA LENGKAP'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _namaController,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Bagian ini wajib diisi.'
                      : null,
                  decoration:
                      _buildInputDecoration(hintText: 'Contoh: Budi Santoso'),
                ),
                const SizedBox(height: 20),

                // Row for ID NASABAH and JENIS KELAMIN
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('ID NASABAH'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _idNasabahController,
                            onChanged: (_) {
                              // Clear the red border as soon as the ID is edited.
                              if (_kodeHasError) {
                                setState(() => _kodeHasError = false);
                              }
                            },
                            // Only the required check stays inline (short, standard
                            // across the form). The uniqueness check moved to submit
                            // (_handleSimpan) so its longer message shows in full via
                            // AppNotification instead of truncating in this narrow field.
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Bagian ini wajib diisi.'
                                    : null,
                            decoration: _buildInputDecoration(
                              hintText: 'Contoh: NAS-0900',
                              hasError: _kodeHasError,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('JENIS KELAMIN'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _jenisKelamin,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Pilih jenis kelamin.'
                                    : null,
                            hint: const Text('— Pilih —'),
                            decoration: _buildInputDecoration(),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.grey),
                            items:
                                ['Laki-laki', 'Perempuan'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _jenisKelamin = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Field: TANGGAL LAHIR
                _buildLabel('TANGGAL LAHIR'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tanggalLahirController,
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Bagian ini wajib diisi.'
                      : null,
                  decoration: _buildInputDecoration(
                    hintText: 'dd/mm/yyyy',
                  ).copyWith(
                    suffixIcon: Icon(Icons.calendar_today,
                        color: Colors.grey[600], size: 20),
                  ),
                ),
                const SizedBox(height: 20),

                // Field: NOMOR WHATSAPP
                _buildLabel('NOMOR WHATSAPP'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (_) {
                    // Clear the backend duplicate error as soon as the number is
                    // edited, so the inline red text disappears while typing.
                    if (_serverPhoneError != null) {
                      setState(() => _serverPhoneError = null);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor WhatsApp wajib diisi.';
                    }
                    final regex = RegExp(r'^8[1-9][0-9]{7,11}$');
                    if (!regex.hasMatch(value)) {
                      return 'Format nomor tidak valid. Mulai dengan angka 8';
                    }
                    if (_serverPhoneError != null) return _serverPhoneError;
                    return null;
                  },
                  decoration: _buildInputDecoration(
                    hintText: '812-3456-7890',
                  ).copyWith(
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '+62',
                            style: AppTextStyle.small.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 20),

                // Field: ALAMAT LENGKAP
                _buildLabel('ALAMAT LENGKAP'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _alamatController,
                  maxLines: 4,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Bagian ini wajib diisi.'
                      : null,
                  decoration: _buildInputDecoration(
                    hintText: 'Nama jalan, RT/RW, Kelurahan...',
                  ),
                ),
                const SizedBox(height: 32),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSimpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                      disabledBackgroundColor:
                          AppColors.greenDark.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Simpan Nasabah',
                            style: AppTextStyle.title1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSimpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<NasabahCubit>();
    final kode = _idNasabahController.text.trim();

    // Uniqueness check, moved out of the inline validator: a duplicate ID gets a
    // full, readable message in a notification plus a red border on the field,
    // and still blocks the save.
    if (cubit.state is NasabahLoaded) {
      final list = (cubit.state as NasabahLoaded).nasabahList;
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
      jenisKelamin: _jenisKelamin ?? 'Laki-laki',
      tanggalLahir: _tanggalLahirController.text.trim(),
      noHp: '+62${_whatsappController.text.trim()}',
      alamat: _alamatController.text.trim(),
    );

    final error = await cubit.addNasabah(request);
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

    if (kodeError != null) {
      setState(() => _kodeHasError = true);
      AppNotification.showError(
        context,
        title: 'ID Nasabah Sudah Digunakan',
        message: kodeError,
      );
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyle.extraSmall.copyWith(
        color: Colors.grey[500],
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {String? hintText, bool hasError = false}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      // [hasError] paints the border red without any inline text — used to flag
      // the compact ID field when its message is shown in an AppNotification.
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: hasError ? Colors.red : Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? Colors.red : AppColors.greenDark,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
