import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/harga_confirmation_dialog.dart';

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
  bool _isSaving = false;
  String? _serverKodeError;

  /// Dropdown options as (API value, display label, icon). The value is what the
  /// backend `JenisSampah.Kategori` choices accept and is stored in
  /// [_selectedCategory]; the label is display-only. They differ for "Lainnya",
  /// which maps to the backend's catch-all `dll` — there is no `lainnya` choice.
  static const List<({String value, String label, IconData icon})> _categories = [
    (value: 'kertas', label: 'Kertas', icon: Icons.description),
    (value: 'plastik', label: 'Plastik', icon: Icons.recycling),
    (value: 'logam', label: 'Logam', icon: Icons.settings),
    (value: 'kaca', label: 'Kaca', icon: Icons.wine_bar),
    (value: 'dll', label: 'Lainnya', icon: Icons.category_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _kodeSampahController = TextEditingController(text: widget.initialData?.kodeSampah ?? '');
    _nameController = TextEditingController(text: widget.initialData?.name ?? '');
    _descController = TextEditingController(text: widget.initialData?.subtitle ?? '');

    // The dropdown holds the backend value verbatim, so edit mode preselects by
    // matching the stored category directly. An unknown category (e.g. organik,
    // which has no dropdown entry) leaves the field empty rather than
    // silently rewriting it to a category the user never chose.
    final cat = widget.initialData?.category.toLowerCase();
    if (cat != null && _categories.any((c) => c.value == cat)) {
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
                  onChanged: (_) {
                    if (_serverKodeError != null) {
                      setState(() => _serverKodeError = null);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Bagian ini wajib diisi.';
                    final cubit = widget.hargaCubit ?? context.read<HargaCubit>();
                    if (cubit.state is HargaLoaded) {
                      final list = (cubit.state as HargaLoaded).jenisSampahList;
                      final isDuplicate = list.any((e) => e.kodeSampah.trim().toLowerCase() == value.trim().toLowerCase() && e.id != widget.initialData?.id);
                      if (isDuplicate) return 'Kode sampah ini sudah digunakan.';
                    }
                    if (_serverKodeError != null) return _serverKodeError;
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
                  items: _categories.map(_buildDropdownItem).toList(),
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
                    onPressed: _isSaving ? null : _handleSimpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                      disabledBackgroundColor: AppColors.greenDark.withValues(alpha: 0.6),
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEditMode ? 'Simpan Perubahan' : 'Simpan Jenis Sampah',
                            style: AppTextStyle.title1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                // Activate / Deactivate (edit mode only)
                if (isEditMode) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _handleToggleStatus,
                      icon: Icon(
                        _isActive ? Icons.block : Icons.check_circle_outline,
                        size: 20,
                        color: _isActive ? Colors.red[600] : AppColors.greenDark,
                      ),
                      label: Text(
                        _isActive ? 'Nonaktifkan Jenis Sampah' : 'Aktifkan Jenis Sampah',
                        style: AppTextStyle.title1.copyWith(
                          color: _isActive ? Colors.red[600] : AppColors.greenDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: _isActive ? Colors.red[200]! : AppColors.greenLight,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isActive => widget.initialData?.isActive ?? true;

  Future<void> _handleToggleStatus() async {
    final cubit = widget.hargaCubit ?? context.read<HargaCubit>();
    final id = widget.initialData!.id;
    final wasActive = _isActive;

    // Confirm before touching the API. A cancel or a barrier dismiss returns
    // false, and nothing has changed at this point, so there is no optimistic
    // UI state to roll back.
    final confirmed = await HargaConfirmationDialog.show(
      context,
      isActivating: !wasActive,
      wasteName: widget.initialData!.name,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    final error =
        wasActive ? await cubit.deactivateHarga(id) : await cubit.activateHarga(id);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      context.pop();
      AppNotification.showSuccess(
        context,
        title: 'Berhasil',
        message: wasActive
            ? 'Jenis sampah berhasil dinonaktifkan.'
            : 'Jenis sampah berhasil diaktifkan.',
      );
      return;
    }

    AppNotification.showError(
      context,
      title: 'Gagal',
      message: error.displayMessage,
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
    ({String value, String label, IconData icon}) category,
  ) {
    return DropdownMenuItem<String>(
      value: category.value,
      child: Row(
        children: [
          Icon(category.icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(category.label),
        ],
      ),
    );
  }

  Future<void> _handleSimpan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = widget.hargaCubit ?? context.read<HargaCubit>();
    final isEditMode = widget.initialData != null;

    final int priceVal = int.tryParse(_priceController.text) ?? 0;
    final String formattedPrice =
        'Rp ${_priceController.text.replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ".")}';

    final harga = HargaEntity(
      id: widget.initialData?.id ?? '',
      kodeSampah: _kodeSampahController.text.trim(),
      name: _nameController.text.trim(),
      price: priceVal,
      priceFormatted: formattedPrice,
      category: _selectedCategory ?? 'dll',
      subtitle: _descController.text.trim(),
      badgeText: widget.initialData?.badgeText ?? 'Anorganik',
      icon: widget.initialData?.icon ?? Icons.recycling,
      iconColor: widget.initialData?.iconColor ?? AppColors.greenDark,
      isActive: widget.initialData?.isActive ?? true,
    );

    setState(() => _isSaving = true);
    final error = isEditMode ? await cubit.updateHarga(harga) : await cubit.addHarga(harga);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error == null) {
      context.pop();
      AppNotification.showSuccess(
        context,
        title: 'Berhasil',
        message: isEditMode
            ? 'Jenis sampah berhasil diperbarui.'
            : 'Jenis sampah baru berhasil ditambahkan.',
      );
      return;
    }

    final fields = error.fieldErrors();
    if (fields.containsKey('kode')) {
      setState(() => _serverKodeError = fields['kode']);
      _formKey.currentState?.validate();
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
