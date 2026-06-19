import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class ItemSetoranCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> itemData;
  final List<Map<String, dynamic>> jenisSampahList;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;

  const ItemSetoranCard({
    super.key,
    required this.index,
    required this.itemData,
    required this.jenisSampahList,
    required this.onChanged,
    required this.onDelete,
  });

  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorColor = Color(0xFFDC2626);

  String _formatCurrency(int value) {
    String str = value.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = itemData['jenis'] as String?;
    final harga = itemData['harga'] as int? ?? 0;
    final berat = itemData['berat'] as int? ?? 1;
    final subtotal = harga * berat;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Dropdown & Delete Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedType,
                      hint: Row(
                        children: [
                          const Icon(Icons.recycling, color: emeraldPrimary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pilih Jenis',
                            style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                      items: jenisSampahList.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['name'],
                          child: Row(
                            children: [
                              Icon(type['icon'] as IconData, color: type['iconColor'] as Color, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                type['name'] as String,
                                style: AppTextStyle.small.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final selected = jenisSampahList.firstWhere((t) => t['name'] == value);
                          onChanged({
                            ...itemData,
                            'jenis': value,
                            'harga': selected['price'],
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: errorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, color: errorColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Harga
          Row(
            children: [
              Text(
                'Harga/kg:',
                style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Text(
                        'Rp',
                        style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: harga > 0 ? harga.toString() : '',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 12),
                        ),
                        style: AppTextStyle.small.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (val) {
                          final newHarga = int.tryParse(val) ?? 0;
                          onChanged({
                            ...itemData,
                            'harga': newHarga,
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/kg',
                style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Berat & Subtotal
          Row(
            children: [
              // Stepper
              Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (berat > 1) {
                          onChanged({
                            ...itemData,
                            'berat': berat - 1,
                          });
                        }
                      },
                      child: Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Icon(Icons.remove, color: Colors.grey[600], size: 16),
                      ),
                    ),
                    Container(width: 1, color: Colors.grey[200]),
                    SizedBox(
                      width: 40,
                      child: Text(
                        berat.toString(),
                        textAlign: TextAlign.center,
                        style: AppTextStyle.small.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(width: 1, color: Colors.grey[200]),
                    InkWell(
                      onTap: () {
                        onChanged({
                          ...itemData,
                          'berat': berat + 1,
                        });
                      },
                      child: Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Icon(Icons.add, color: Colors.grey[600], size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg',
                style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
              ),
              const Spacer(),
              // Subtotal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    _formatCurrency(subtotal),
                    style: AppTextStyle.title1.copyWith(
                      color: emeraldPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
