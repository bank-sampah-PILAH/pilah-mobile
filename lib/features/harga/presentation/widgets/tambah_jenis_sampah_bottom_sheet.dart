import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

class TambahJenisSampahBottomSheet extends StatefulWidget {
  final HargaEntity? initialData;
  final HargaCubit? hargaCubit;

  const TambahJenisSampahBottomSheet({super.key, this.initialData, this.hargaCubit});

  @override
  State<TambahJenisSampahBottomSheet> createState() => _TambahJenisSampahBottomSheetState();
}

class _TambahJenisSampahBottomSheetState extends State<TambahJenisSampahBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _kodeSampahController;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _kodeSampahController = TextEditingController(text: widget.initialData?.kodeSampah ?? '');
    _nameController = TextEditingController(text: widget.initialData?.name ?? '');
    _descController = TextEditingController(text: widget.initialData?.subtitle ?? '');
    
    // Set category if available
    final cat = widget.initialData?.category;
    if (['Kertas', 'Plastik', 'Logam', 'Kaca'].contains(cat)) {
      _selectedCategory = cat;
    }
    
    // Process price string
    String initialPrice = '';
    if (widget.initialData != null) {
      initialPrice = widget.initialData!.price.toString();
    }
    _priceController = TextEditingController(text: initialPrice);
  }

  @override
  void dispose() {
    _kodeSampahController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.initialData != null;
    
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
                BottomSheetHeader(
                  title: isEditMode ? 'Edit Jenis Sampah' : 'Tambah Jenis Sampah',
                ),
                const SizedBox(height: 24),

                // Field: ID / KODE SAMPAH
                _buildLabel('ID / KODE SAMPAH'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _kodeSampahController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Bagian ini wajib diisi.';
                    final cubit = widget.hargaCubit ?? context.read<HargaCubit>();
                    if (cubit.state is HargaLoaded) {
                      final list = (cubit.state as HargaLoaded).jenisSampahList;
                      final isDuplicate = list.any((e) => e.kodeSampah.trim().toLowerCase() == value.trim().toLowerCase() && e.id != widget.initialData?.id);
                      if (isDuplicate) return 'Kode sampah ini sudah digunakan.';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration(hintText: 'Contoh: PLS-001'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kode unik untuk identifikasi jenis sampah ini.',
                  style: AppTextStyle.small.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 20),

                // Field: NAMA JENIS SAMPAH
                _buildLabel('NAMA JENIS SAMPAH'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Bagian ini wajib diisi.' : null,
                  decoration: _buildInputDecoration(hintText: 'Contoh: Plastik PET'),
                ),
                const SizedBox(height: 20),

                // Field: KATEGORI
                _buildLabel('KATEGORI'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  validator: (value) => (value == null || value.isEmpty) ? 'Bagian ini wajib diisi.' : null,
                  hint: const Text('— Pilih Kategori —'),
                  decoration: _buildInputDecoration(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: [
                    _buildDropdownItem('Kertas', Icons.description),
                    _buildDropdownItem('Plastik', Icons.recycling),
                    _buildDropdownItem('Logam', Icons.settings),
                    _buildDropdownItem('Kaca', Icons.wine_bar),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Field: DESKRIPSI (OPSIONAL)
                _buildLabel('DESKRIPSI (OPSIONAL)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: _buildInputDecoration(hintText: 'Contoh: Botol bening, kemasan plastik'),
                ),
                const SizedBox(height: 20),

                // Field: HARGA BELI PER KG (RP)
                _buildLabel('HARGA BELI PER KG (RP)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Bagian ini wajib diisi.' : null,
                  decoration: _buildInputDecoration(
                    hintText: '0',
                  ).copyWith(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14),
                      child: Text(
                        'Rp',
                        style: AppTextStyle.title1.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Harga yang akan dibayarkan ke nasabah.',
                  style: AppTextStyle.small.copyWith(
                    color: Colors.grey[500],
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
                      isEditMode ? 'Simpan Perubahan' : 'Simpan Jenis Sampah',
                      style: AppTextStyle.title1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String text, IconData icon) {
    return DropdownMenuItem<String>(
      value: text,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  void _handleSimpan() {
    if (_formKey.currentState?.validate() ?? false) {
      final cubit = widget.hargaCubit ?? context.read<HargaCubit>();
      final isEditMode = widget.initialData != null;
      
      final int priceVal = int.tryParse(_priceController.text) ?? 0;
      final String formattedPrice = 'Rp ${_priceController.text.replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ".")}';
      
      if (isEditMode) {
        final updatedHarga = HargaEntity(
          id: widget.initialData!.id,
          kodeSampah: _kodeSampahController.text,
          name: _nameController.text,
          price: priceVal,
          priceFormatted: formattedPrice,
          category: _selectedCategory ?? 'Lainnya',
          subtitle: _descController.text,
          badgeText: widget.initialData!.badgeText,
          icon: widget.initialData!.icon,
          iconColor: widget.initialData!.iconColor,
          isActive: widget.initialData!.isActive,
        );
        cubit.updateHarga(updatedHarga);
        context.pop();
        AppNotification.showSuccess(context, title: 'Berhasil', message: 'Jenis sampah berhasil diperbarui.');
      } else {
        final newHarga = HargaEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          kodeSampah: _kodeSampahController.text,
          name: _nameController.text,
          price: priceVal,
          priceFormatted: formattedPrice,
          category: _selectedCategory ?? 'Lainnya',
          subtitle: _descController.text,
          badgeText: 'Anorganik',
          icon: Icons.recycling,
          iconColor: AppColors.greenDark,
          isActive: true,
        );
        cubit.addHarga(newHarga);
        context.pop();
        AppNotification.showSuccess(context, title: 'Berhasil', message: 'Jenis sampah baru berhasil ditambahkan.');
      }
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
