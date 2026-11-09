import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/states/harga_state.dart';

class PilihJenisSampahPicker extends ConsumerStatefulWidget {
  const PilihJenisSampahPicker({
    super.key,
    required this.selectedId,
  });
  final String? selectedId;

  @override
  ConsumerState<PilihJenisSampahPicker> createState() =>
      _PilihJenisSampahPickerState();
}

class _PilihJenisSampahPickerState
    extends ConsumerState<PilihJenisSampahPicker> {
  String _query = '';
  String _category = '';

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(hargaProvider);
    final catalog = ref.read(hargaProvider.notifier).activeJenisSampah;
    final categories = catalog
        .map((item) => item.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final category = categories.contains(_category) ? _category : '';
    final options = catalog
        .where((item) =>
            (category.isEmpty || item.category == category) &&
            item.name.toLowerCase().contains(_query))
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
          if (categories.isNotEmpty)
            DropdownButton<String>(
              value: category,
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Semua kategori'),
                ),
                for (final category in categories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category == 'dll'
                        ? 'Lainnya'
                        : category[0].toUpperCase() + category.substring(1)),
                  ),
              ],
              onChanged: (value) => setState(() => _category = value ?? ''),
            ),
          Expanded(
            child: catalog.isEmpty && catalogState is HargaLoading
                ? const Center(child: CircularProgressIndicator())
                : options.isEmpty
                    ? Center(
                        child: Text(catalog.isEmpty
                            ? (catalogState is HargaError
                                ? catalogState.message
                                : 'Belum ada jenis sampah aktif')
                            : 'Jenis sampah tidak ditemukan'),
                      )
                    : ListView.builder(
                        key: ValueKey((_query, category)),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final item = options[index];
                          return ListTile(
                            leading: Icon(item.icon, color: item.iconColor),
                            title: Text(item.name),
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
