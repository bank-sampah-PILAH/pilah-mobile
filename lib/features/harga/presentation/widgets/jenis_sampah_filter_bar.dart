import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_sort_button.dart';
import 'package:pilah_mobile/features/harga/domain/models/jenis_sampah_query.dart';

/// Cari, filter kategori, dan urut untuk daftar jenis sampah.
///
/// Tidak menyimpan keadaan bisnis: pemakai memegang [query] dan memakainya
/// lewat [JenisSampahQuery.apply]. [kategori] adalah kategori yang ada di data
/// (lihat [kategoriTersedia]); kalau hanya satu, chip filter disembunyikan
/// karena tidak ada yang bisa dipilih.
class JenisSampahFilterBar extends StatefulWidget {
  const JenisSampahFilterBar({
    super.key,
    required this.query,
    required this.kategori,
    required this.onChanged,
    this.showKategori = true,
  });

  /// Bila `false`, chip kategori tidak digambar di sini; pemakai menaruhnya
  /// sendiri dengan [JenisSampahKategoriFilter] (mis. di baris tab).
  final bool showKategori;
  final JenisSampahQuery query;
  final List<String> kategori;
  final ValueChanged<JenisSampahQuery> onChanged;

  static String labelUrutan(JenisSampahSortField field) => switch (field) {
        JenisSampahSortField.nama => 'Nama',
        JenisSampahSortField.harga => 'Harga',
      };

  @override
  State<JenisSampahFilterBar> createState() => _JenisSampahFilterBarState();
}

class _JenisSampahFilterBarState extends State<JenisSampahFilterBar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query.search);

  @override
  void didUpdateWidget(JenisSampahFilterBar old) {
    super.didUpdateWidget(old);
    // Query diganti dari luar (mis. "Reset filter"): isi kolom cari menyusul.
    if (widget.query.search != _controller.text) {
      _controller.text = widget.query.search;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Memilih bidang yang sama membalik arah; bidang lain mulai dari kecil ke
  /// besar (A-Z, termurah).
  void _urut(JenisSampahSortField field) {
    final q = widget.query;
    widget.onChanged(field == q.sortField
        ? q.copyWith(ascending: !q.ascending)
        : q.copyWith(sortField: field, ascending: true));
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomSearchField(
                key: const Key('cari-jenis-sampah'),
                hintText: 'Cari nama atau kode jenis sampah',
                controller: _controller,
                onChanged: (v) => widget.onChanged(q.copyWith(search: v)),
              ),
            ),
            const SizedBox(width: 8),
            PencairanSortButton<JenisSampahSortField>(
              buttonKey: const Key('urutkan-jenis-sampah'),
              itemKeyPrefix: 'urut-jenis-sampah-',
              fields: JenisSampahSortField.values,
              labelOf: JenisSampahFilterBar.labelUrutan,
              current: q.sortField,
              ascending: q.ascending,
              onSort: _urut,
            ),
          ],
        ),
        if (widget.showKategori && widget.kategori.length > 1) ...[
          const SizedBox(height: 8),
          JenisSampahKategoriFilter(
            query: q,
            kategori: widget.kategori,
            onChanged: widget.onChanged,
          ),
        ],
      ],
    );
  }
}

/// Filter kategori: satu chip yang membuka daftar centang per kategori.
///
/// Semua tercentang bawaannya dan chip-nya berbunyi "Semua kategori"; satu
/// kategori menuliskan namanya, beberapa menuliskan "N kategori", dan bila
/// tidak satu pun tercentang "Tidak ada kategori". Chip selalu hijau karena
/// filter ini selalu berlaku. Disembunyikan bila tidak ada yang bisa dipilih
/// (kurang dari dua kategori).
class JenisSampahKategoriFilter extends StatelessWidget {
  const JenisSampahKategoriFilter({
    super.key,
    required this.query,
    required this.kategori,
    required this.onChanged,
  });

  final JenisSampahQuery query;
  final List<String> kategori;
  final ValueChanged<JenisSampahQuery> onChanged;

  static const _lebarMenu = 240.0;

  @override
  Widget build(BuildContext context) {
    if (kategori.length < 2) return const SizedBox.shrink();
    final terpilih = query.kategoriTerpilih(kategori);
    final semua = terpilih.length == kategori.length;
    return MenuAnchor(
      consumeOutsideTap: true,
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8),
        ),
        fixedSize: const WidgetStatePropertyAll(Size.fromWidth(_lebarMenu)),
      ),
      menuChildren: [
        // Menu tetap terbuka setelah satu pilihan, supaya beberapa kategori
        // dapat dicentang berurutan; ia menutup saat menekan di luar.
        CheckboxMenuButton(
          key: const Key('kategori-semua'),
          closeOnActivate: false,
          value: semua,
          // Semua tercentang: mencabut semuanya. Selain itu: memilih semua.
          onChanged: (_) => onChanged(query.toggleSemuaKategori(kategori)),
          child: const Text('Semua kategori'),
        ),
        for (final k in kategori)
          CheckboxMenuButton(
            key: Key('kategori-$k'),
            closeOnActivate: false,
            value: terpilih.contains(k),
            onChanged: (_) => onChanged(query.toggleKategori(k, kategori)),
            child: Text(labelKategori(k)),
          ),
      ],
      builder: (context, controller, _) => AppChip(
        key: const Key('filter-kategori'),
        label: labelFilterKategori(query, kategori),
        // Selalu hijau: filter ini selalu berlaku, termasuk saat semua
        // kategori tercentang.
        selected: true,
        trailingIcon: Icons.keyboard_arrow_down,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
