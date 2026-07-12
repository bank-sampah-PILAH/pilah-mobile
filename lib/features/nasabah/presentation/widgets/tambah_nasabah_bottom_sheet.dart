import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';

class TambahNasabahBottomSheet extends StatefulWidget {
  const TambahNasabahBottomSheet({super.key});

  @override
  State<TambahNasabahBottomSheet> createState() => _TambahNasabahBottomSheetState();
}

class _TambahNasabahBottomSheetState extends State<TambahNasabahBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  final _namaController = TextEditingController();
  final _idNasabahController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _alamatController = TextEditingController();

  String? _jenisKelamin;

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
                        child: Icon(Icons.close, color: Colors.grey[600], size: 20),
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
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Bagian ini wajib diisi.' : null,
                  decoration: _buildInputDecoration(hintText: 'Contoh: Budi Santoso'),
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
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Bagian ini wajib diisi.';
                              final cubit = context.read<NasabahCubit>();
                              if (cubit.state is NasabahLoaded) {
                                final list = (cubit.state as NasabahLoaded).nasabahList;
                                final isDuplicate = list.any((e) => e.idNasabah.trim().toLowerCase() == value.trim().toLowerCase());
                                if (isDuplicate) return 'ID Nasabah ini sudah digunakan.';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(hintText: 'Contoh: NAS-0900'),
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
                            value: _jenisKelamin,
                            validator: (value) => (value == null || value.isEmpty) ? 'Pilih jenis kelamin.' : null,
                            hint: const Text('— Pilih —'),
                            decoration: _buildInputDecoration(),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            items: ['Laki-laki', 'Perempuan'].map((String value) {
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
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Bagian ini wajib diisi.' : null,
                  decoration: _buildInputDecoration(
                    hintText: 'dd/mm/yyyy',
                  ).copyWith(
                    suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor WhatsApp wajib diisi.';
                    }
                    final regex = RegExp(r'^8[1-9][0-9]{7,11}$');
                    if (!regex.hasMatch(value)) {
                      return 'Format nomor tidak valid. Mulai dengan angka 8';
                    }
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
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 20),

                // Field: ALAMAT LENGKAP
                _buildLabel('ALAMAT LENGKAP'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _alamatController,
                  maxLines: 4,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Bagian ini wajib diisi.' : null,
                  decoration: _buildInputDecoration(
                    hintText: 'Nama jalan, RT/RW, Kelurahan...',
                  ),
                ),
                const SizedBox(height: 32),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSimpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
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

  void _handleSimpan() {
    if (_formKey.currentState?.validate() ?? false) {
      final nomorWhatsapp = '+62${_whatsappController.text}';
      debugPrint('Nasabah disimpan dengan nomor: $nomorWhatsapp');
      
      // Usually, you would create NasabahEntity here and send to Cubit:
      // final nasabah = NasabahEntity(
      //   id: DateTime.now().millisecondsSinceEpoch.toString(),
      //   idNasabah: _idNasabahController.text,
      //   name: _namaController.text,
      //   jenisKelamin: _jenisKelamin ?? 'Laki-laki',
      //   tanggalLahir: _tanggalLahirController.text,
      //   phone: nomorWhatsapp,
      //   address: _alamatController.text,
      //   balance: 'Rp 0',
      //   isActive: true,
      //   initials: _namaController.text.isNotEmpty ? _namaController.text[0] : 'U',
      //   avatarColor: AppColors.greenLight,
      //   textColor: AppColors.greenDark,
      // );
      
      context.pop();
      AppNotification.showSuccess(
        context,
        title: 'Berhasil',
        message: 'Nasabah baru berhasil ditambahkan.',
      );
    }
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

  InputDecoration _buildInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.greenDark, width: 1.5),
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
