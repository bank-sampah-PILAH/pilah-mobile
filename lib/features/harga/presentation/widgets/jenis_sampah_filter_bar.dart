import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_sort_button.dart';
import 'package:pilah_mobile/features/harga/domain/models/jenis_sampah_query.dart';

/// Cari dan urut untuk daftar jenis sampah.
///
/// Tidak menyimpan keadaan bisnis: pemakai memegang [query] dan memakainya
/// lewat [JenisSampahQuery.apply].
class JenisSampahFilterBar extends StatefulWidget {
  const JenisSampahFilterBar({
    super.key,
    required this.query,
    required this.onChanged,
  });

  final JenisSampahQuery query;
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
      ],
    );
  }
}
