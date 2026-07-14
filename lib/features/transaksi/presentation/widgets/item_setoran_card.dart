import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

class ItemSetoranCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> itemData;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;
  final bool hasError;
  final String? errorText;

  const ItemSetoranCard({
    super.key,
    required this.index,
    required this.itemData,
    required this.onChanged,
    required this.onDelete,
    this.hasError = false,
    this.errorText,
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
    final berat = itemData['berat'] as num? ?? 1.0;
    final subtotal = (harga * berat).round();

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
                    border: Border.all(color: hasError ? errorColor : Colors.grey[200]!),
                  ),
                  child: BlocBuilder<HargaCubit, HargaState>(
                    builder: (context, state) {
                      // Source the options from the full active list rather than
                      // the price-list page's tab/search-filtered state, so the
                      // dropdown always offers every active jenis sampah. The
                      // BlocBuilder still rebuilds this once loadHarga() completes.
                      final List<HargaEntity> activeList =
                          context.read<HargaCubit>().activeJenisSampah;
                      // Guard against a stale selection no longer in the list
                      // (e.g. a jenis that was deactivated): DropdownButton
                      // asserts if its value has no matching item.
                      final selectedValue =
                          activeList.any((t) => t.name == selectedType)
                              ? selectedType
                              : null;

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedValue,
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
                          items: activeList.map((type) {
                            return DropdownMenuItem<String>(
                              value: type.name,
                              child: Row(
                                children: [
                                  Icon(type.icon, color: type.iconColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    type.name,
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
                              final selected = activeList.firstWhere((t) => t.name == value);
                              onChanged({
                                ...itemData,
                                'jenis': value,
                                'jenis_sampah_id': selected.id,
                                'harga': selected.price,
                              });
                            }
                          },
                        ),
                      );
                    },
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
          if (hasError && errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: AppTextStyle.small.copyWith(color: errorColor, fontSize: 12),
            ),
          ],
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
                        key: ValueKey(harga),
                        initialValue: harga > 0 ? _formatCurrency(harga).replaceAll('Rp ', '') : '',
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 12),
                        ),
                        style: AppTextStyle.small.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
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
              // Berat Input
              Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextFormField(
                  initialValue: berat == 1.0 ? '1' : (berat % 1 == 0 ? berat.toInt().toString() : berat.toString()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textAlign: TextAlign.center,
                  style: AppTextStyle.small.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(bottom: 12),
                  ),
                  onChanged: (value) {
                    final cleanValue = value.replaceAll(',', '.');
                    final newBerat = num.tryParse(cleanValue) ?? 0.0;
                    onChanged({
                      ...itemData,
                      'berat': newBerat,
                    });
                  },
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
