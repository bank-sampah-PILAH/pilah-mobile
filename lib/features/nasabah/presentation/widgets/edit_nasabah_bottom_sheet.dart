import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_form_fields.dart';

/// Pesan 403 yang berarti profilnya milik pemilik akun (PIL-223). Endpoint
/// ini juga membalas 403 untuk nasabah nonaktif dengan pesan lain, jadi
/// status code sendirian tidak cukup untuk mengunci form.
const _pesanEmailTerkunci = 'Email nasabah dengan akun tidak dapat diubah';

class EditNasabahBottomSheet extends ConsumerStatefulWidget {
  /// Nasabah yang disunting, memakai entity domain apa adanya.
  final NasabahEntity nasabah;

  const EditNasabahBottomSheet({
    super.key,
    required this.nasabah,
  });

  @override
  ConsumerState<EditNasabahBottomSheet> createState() =>
      _EditNasabahBottomSheetState();
}

class _EditNasabahBottomSheetState
    extends ConsumerState<EditNasabahBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _idNasabahController;
  late TextEditingController _emailController;
  late TextEditingController _tanggalLahirController;
  late TextEditingController _whatsappController;
  late TextEditingController _alamatController;

  String? _jenisKelamin;
  bool _isSaving = false;

  /// Email menjadi kunci penautan ke akun begitu keanggotaan tertaut, jadi
  /// hanya field itu yang tidak boleh disunting pengurus (PIL-288). Field
  /// dimatikan agar pengurus tidak mengetik data yang pasti ditolak 403.
  /// Default tidak terkunci: pemanggil lama belum mengirim penandanya.
  bool get _emailTerkunci => _ditolakServer || widget.nasabah.punyaAkun;

  /// Server menolak perubahan profil walau penanda dari daftar belum
  /// menyatakannya. Nasabah dapat menautkan akunnya setelah daftar dimuat,
  /// sehingga penanda itu boleh basi; keputusan server yang menentukan.
  bool _ditolakServer = false;
  String? _serverKodeError;
  String? _serverEmailError;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.nasabah.name);
    _idNasabahController =
        TextEditingController(text: widget.nasabah.idNasabah);
    _emailController = TextEditingController(text: widget.nasabah.email);

    // Safely parse jenis kelamin
    final jk = widget.nasabah.jenisKelamin;
    if (jk == 'Laki-laki' || jk == 'Perempuan') {
      _jenisKelamin = jk;
    }

    _tanggalLahirController =
        TextEditingController(text: widget.nasabah.tanggalLahir);

    // Strip +62 safely
    String phone = widget.nasabah.phone;
    if (phone.isNotEmpty) {
      if (phone.startsWith('+62')) {
        phone = phone.substring(3);
      } else if (phone.startsWith('0')) {
        phone = phone.substring(1);
      } else if (phone.startsWith('62')) {
        phone = phone.substring(2);
      }
    }
    _whatsappController = TextEditingController(text: phone);

    _alamatController = TextEditingController(text: widget.nasabah.address);
  }

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
      title: 'Edit Nasabah',
      formKey: _formKey,
      notice: _emailTerkunci ? _buildKeteranganEmailTerkunci() : null,
      fields: [
        NasabahNameField(controller: _namaController),
        NasabahFieldPair(
          left: NasabahIdField(
            controller: _idNasabahController,
            hintText: 'Contoh: NAS-0900',
            onChanged: () {
              if (_serverKodeError != null) {
                setState(() => _serverKodeError = null);
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bagian ini wajib diisi.';
              }
              final state = ref.read(nasabahProvider);
              if (state is NasabahLoaded) {
                final list = state.nasabahList;
                final isDuplicate = list.any((e) =>
                    e.idNasabah.trim().toLowerCase() ==
                        value.trim().toLowerCase() &&
                    e.id != widget.nasabah.id);
                if (isDuplicate) return 'ID Nasabah ini sudah digunakan.';
              }
              return _serverKodeError;
            },
          ),
          right: NasabahGenderField(
            value: _jenisKelamin,
            onChanged: (jenis) => setState(() => _jenisKelamin = jenis),
          ),
        ),
        NasabahEmailField(
          controller: _emailController,
          enabled: !_emailTerkunci,
          serverError: () => _serverEmailError,
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
        NasabahPhoneField(controller: _whatsappController),
        NasabahAddressField(
          controller: _alamatController,
          validator: (value) =>
              (value == null || value.trim().runes.length < 10)
                  ? 'Alamat minimal 10 karakter.'
                  : null,
        ),
      ],
      button: AppButton(
        label: 'Simpan Perubahan',
        isLoading: _isSaving,
        onPressed: _handleSimpan,
      ),
    );
  }

  Future<void> _handleSimpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final id = widget.nasabah.id;
    if (id.isEmpty) return;

    setState(() => _isSaving = true);
    final notifier = ref.read(nasabahProvider.notifier);
    final request = NasabahRequest(
      kode: _idNasabahController.text.trim(),
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      jenisKelamin: _jenisKelamin ?? 'Laki-laki',
      tanggalLahir: _tanggalLahirController.text.trim(),
      noHp: '+62${_whatsappController.text.trim()}',
      alamat: _alamatController.text.trim(),
    );

    final error = await notifier.updateNasabah(id, request);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      context.pop();
      AppNotification.showSuccess(
        context,
        title: 'Berhasil',
        message: 'Perubahan data nasabah berhasil disimpan.',
      );
      return;
    }

    // 403 pada endpoint ini punya dua penyebab: nasabah nonaktif (diperiksa
    // lebih dulu di pilah-be) dan profil milik pemilik akun (PIL-223).
    // Hanya pesan yang kedua berarti profilnya terkunci; menyamakan keduanya
    // lewat status code saja mengunci nasabah nonaktif tanpa akun juga.
    if (error.response?.statusCode == 403 &&
        error.displayMessage == _pesanEmailTerkunci) {
      setState(() => _ditolakServer = true);
    }

    final fields = error.fieldErrors();
    if (fields.containsKey('kode')) {
      setState(() => _serverKodeError = fields['kode']);
      _formKey.currentState?.validate();
    }
    if (fields.containsKey('email')) {
      setState(() => _serverEmailError = fields['email']);
      _formKey.currentState?.validate();
    }
    AppNotification.showError(
      context,
      title: 'Gagal Menyimpan',
      message: error.displayMessage,
    );
  }

  /// Menjelaskan mengapa sebagian field tidak dapat disunting.
  ///
  /// Penjelasan tampilan saja; penolakannya tetap diputuskan server pada
  /// setiap permintaan (PIL-223, OWASP A01 Broken Access Control).
  Widget _buildKeteranganEmailTerkunci() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.greenDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email dikelola oleh nasabah',
                  style: AppTextStyle.title1.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nasabah ini sudah punya akun. Emailnya menjadi kunci masuk, jadi hanya itu yang tidak dapat diubah.',
                  style: AppTextStyle.small.copyWith(
                    color: Colors.black87,
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
}
