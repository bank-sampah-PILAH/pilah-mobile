import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

class PilihJenisSampahPicker extends StatelessWidget {
  const PilihJenisSampahPicker({
    super.key,
    required this.options,
    required this.selectedId,
  });

  final List<HargaEntity> options;
  final String? selectedId;

  @override
  Widget build(BuildContext context) => SafeArea(
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
            Expanded(
              child: options.isEmpty
                  ? const Center(child: Text('Belum ada jenis sampah aktif'))
                  : ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final item = options[index];
                        return ListTile(
                          leading: Icon(item.icon, color: item.iconColor),
                          title: Text(item.name),
                          subtitle: Text(item.priceFormatted),
                          selected: item.id == selectedId,
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
}
