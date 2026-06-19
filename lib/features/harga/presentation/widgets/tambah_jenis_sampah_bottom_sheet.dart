import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_outlined_button.dart';

class TambahJenisSampahBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final HargaCubit? hargaCubit;

  const TambahJenisSampahBottomSheet({super.key, this.initialData, this.hargaCubit});

  @override
  State<TambahJenisSampahBottomSheet> createState() => _TambahJenisSampahBottomSheetState();
}

class _TambahJenisSampahBottomSheetState extends State<TambahJenisSampahBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['title'] ?? '');
    _descController = TextEditingController(text: widget.initialData?['subtitle'] ?? '');
    
    // Process price string "Rp 3.500" to "3500"
    String initialPrice = '';
    if (widget.initialData?['price'] != null) {
      initialPrice = widget.initialData!['price'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    }
    _priceController = TextEditingController(text: initialPrice);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.initialData != null;
    const Color errorColor = Color(0xFFDC2626); // from colors.txt requested red/error
    
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BottomSheetHeader(
                title: isEditMode ? 'Edit Jenis Sampah' : 'Tambah Jenis Sampah',
              ),
              const SizedBox(height: 24),

              // Field 1: NAMA JENIS SAMPAH
              _buildLabel('NAMA JENIS SAMPAH'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hintText: 'Contoh: Plastik PET',
              ),
              const SizedBox(height: 20),

              // Field 2: KATEGORI
              _buildLabel('KATEGORI'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.recycling, color: AppColors.greenDark, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.initialData?['badgeText'] ?? 'Anorganik',
                        style: AppTextStyle.small.copyWith(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Field 3: DESKRIPSI (OPSIONAL)
              _buildLabel('DESKRIPSI (OPSIONAL)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descController,
                hintText: 'Contoh: Botol bening, kemasan plastik',
              ),
              const SizedBox(height: 20),

              // Field 4: HARGA BELI PER KG (RP)
              _buildLabel('HARGA BELI PER KG (RP)'),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: AppTextStyle.small.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: '0',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Harga yang akan dibayarkan ke nasabah.',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 32),

              // Primary Button
              CustomPrimaryButton(
                title: isEditMode ? 'Simpan Perubahan' : 'Simpan Jenis Sampah',
                onPressed: () {
                  if (widget.hargaCubit != null) {
                    final priceString = _priceController.text;
                    final priceInt = int.tryParse(priceString) ?? 0;
                    
                    if (isEditMode && widget.initialData?['id'] != null) {
                      widget.hargaCubit!.updateJenisSampah({
                        'id': widget.initialData!['id'],
                        'name': _nameController.text,
                        'subtitle': _descController.text,
                        'price': priceInt,
                        'priceFormatted': 'Rp ${_priceController.text}',
                      });
                    } else {
                      widget.hargaCubit!.addJenisSampah({
                        'name': _nameController.text,
                        'subtitle': _descController.text,
                        'price': priceInt,
                        'priceFormatted': 'Rp ${_priceController.text}',
                        'category': 'Plastik', // Mocked category
                        'badgeText': 'Anorganik', // Mocked badge
                        'icon': Icons.recycling, // Mocked icon
                        'iconColor': Colors.green, // Mocked color
                      });
                    }
                  }
                  context.pop();
                },
              ),
              
              if (isEditMode) ...[
                const SizedBox(height: 12),
                CustomOutlinedButton(
                  title: 'Nonaktifkan Jenis Sampah',
                  borderColor: errorColor,
                  textColor: errorColor,
                  onPressed: () {
                    if (widget.hargaCubit != null && widget.initialData?['id'] != null) {
                      widget.hargaCubit!.deactivateJenisSampah(widget.initialData!['id']);
                    }
                    context.pop();
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
