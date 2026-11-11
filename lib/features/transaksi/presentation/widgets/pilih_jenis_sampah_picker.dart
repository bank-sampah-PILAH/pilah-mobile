import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/layout/picker_presentation.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/states/harga_state.dart';

class PilihJenisSampahPicker extends ConsumerStatefulWidget {
  const PilihJenisSampahPicker({
    super.key,
    required this.selectedId,
    this.presentation = PickerPresentation.bottomSheet,
  });
  final String? selectedId;
  final PickerPresentation presentation;

  @override
  ConsumerState<PilihJenisSampahPicker> createState() =>
      _PilihJenisSampahPickerState();
}

class _PilihJenisSampahPickerState
    extends ConsumerState<PilihJenisSampahPicker> {
  final _listController = ScrollController();

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  void _resetScroll() {
    if (_listController.hasClients) _listController.jumpTo(0);
  }

  String _query = '';
  String _category = '';

  void _selectCategory(String category) {
    setState(() => _category = category);
    _resetScroll();
  }

  String _categoryLabel(String category) => category == 'dll'
      ? 'Lainnya'
      : category[0].toUpperCase() + category.substring(1);

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
          BottomSheetHeader(
            title: 'Pilih Jenis Sampah',
            showDragHandle: widget.presentation.showsDragHandle,
            showCloseButton: widget.presentation == PickerPresentation.dialog,
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomSearchField(
            hintText: 'Cari nama jenis sampah',
            onChanged: (value) {
              setState(() => _query = value.trim().toLowerCase());
              _resetScroll();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          if (categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  AppChip(
                    label: 'Semua kategori',
                    selected: category.isEmpty,
                    onTap: () => _selectCategory(''),
                  ),
                  for (final option in categories)
                    AppChip(
                      label: _categoryLabel(option),
                      selected: option == category,
                      onTap: () => _selectCategory(option),
                    ),
                ],
              ),
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
                        controller: _listController,
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
