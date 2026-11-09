import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

class PilihJenisSampahPicker extends StatefulWidget {
  const PilihJenisSampahPicker({
    super.key,
    required this.options,
    required this.selectedId,
  });

  final List<HargaEntity> options;
  final String? selectedId;

  @override
  State<PilihJenisSampahPicker> createState() => _PilihJenisSampahPickerState();
}

class _PilihJenisSampahPickerState extends State<PilihJenisSampahPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final options = widget.options
        .where((item) => item.name.toLowerCase().contains(_query))
        .toList();

    return SafeArea(
      child: Column(
        children: [
          ListTile(
            title: const Text('Pilih Jenis Sampah'),
            trailing: IconButton(
              tooltip: 'Tutup',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          CustomSearchField(
            hintText: 'Cari nama jenis sampah',
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: options.isEmpty
                ? Center(
                    child: Text(widget.options.isEmpty
                        ? 'Belum ada jenis sampah aktif'
                        : 'Jenis sampah tidak ditemukan'),
                  )
                : ListView.builder(
                    key: ValueKey(_query),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final item = options[index];
                      return ListTile(
                        leading: Icon(item.icon, color: item.iconColor),
                        title: Text(item.name),
                        subtitle: Text(item.priceFormatted),
                        selected: item.id == widget.selectedId,
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
