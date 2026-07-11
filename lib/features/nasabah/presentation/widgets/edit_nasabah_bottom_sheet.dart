import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class EditNasabahBottomSheet extends StatefulWidget {
  final Map<String, dynamic> customerData;

  const EditNasabahBottomSheet({
    super.key,
    required this.customerData,
  });

  @override
  State<EditNasabahBottomSheet> createState() => _EditNasabahBottomSheetState();
}

class _EditNasabahBottomSheetState extends State<EditNasabahBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  static const Color emeraldPrimary = Color(0xFF006D44);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customerData['name'] ?? '');
    
    // Simple phone formatting for the prefix
    String phone = widget.customerData['phone'] ?? '';
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    } else if (phone.startsWith('+62')) {
      phone = phone.substring(3);
    }
    
    _phoneController = TextEditingController(text: phone);
    _addressController = TextEditingController(text: 'Jl. Mawar No.12, RT.02/03, Kukusan'); // Mocked current address
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
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
                    'Edit Nasabah',
                    style: AppTextStyle.headline1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
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
              Text(
                'Pastikan nomor WhatsApp aktif untuk menerima notifikasi transaksi.',
                style: AppTextStyle.small.copyWith(
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),

              // NAMA LENGKAP
              _buildLabel('NAMA LENGKAP'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: emeraldPrimary),
                  ),
                ),
                style: AppTextStyle.small.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 20),

              // NOMOR WHATSAPP
              _buildLabel('NOMOR WHATSAPP'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                      ),
                      child: Text(
                        '+62',
                        style: AppTextStyle.small.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 48, color: Colors.grey[300]),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor wajib diisi';
                          }
                          final regex = RegExp(r'^8[1-9][0-9]{7,11}$');
                          if (!regex.hasMatch(value)) {
                            return 'Format nomor tidak valid.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: AppTextStyle.small.copyWith(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ALAMAT LENGKAP
              _buildLabel('ALAMAT LENGKAP'),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: emeraldPrimary),
                  ),
                ),
                style: AppTextStyle.small.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 32),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Simpan Perubahan',
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
}
