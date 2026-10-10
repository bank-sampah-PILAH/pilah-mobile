import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import '../../domain/model/draft_pencairan.dart';
import 'draft_format.dart';
import 'pencairan_ui.dart';

/// Asks for the smallest saldo to list, in a white rounded sheet like the one
/// for a nasabah's potongan: amounts to pick with a tap, a field for any other,
/// and a count of who meets it. Returns the amount, or null when dismissed.
Future<int?> showSaldoMinSheet(
  BuildContext context, {
  required List<Kandidat> kandidat,
  required int awal,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SaldoMinSheet(kandidat: kandidat, awal: awal),
  );
}

class _SaldoMinSheet extends StatefulWidget {
  final List<Kandidat> kandidat;
  final int awal;

  const _SaldoMinSheet({required this.kandidat, required this.awal});

  @override
  State<_SaldoMinSheet> createState() => _SaldoMinSheetState();
}

class _SaldoMinSheetState extends State<_SaldoMinSheet> {
  static const _pilihan = [100000, 250000, 500000, 1000000];

  late final TextEditingController _controller = TextEditingController(
    text: widget.awal > 0 ? '${widget.awal}' : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _nilai => int.tryParse(_controller.text) ?? 0;

  String _singkat(int nilai) =>
      nilai >= 1000000 ? 'Rp ${nilai ~/ 1000000} jt' : 'Rp ${nilai ~/ 1000} rb';

  @override
  Widget build(BuildContext context) {
    final nilai = _nilai;
    final memenuhi =
        widget.kandidat.where((k) => !k.kosong && k.saldo >= nilai).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo minimal', style: AppTextStyle.headline3),
          const SizedBox(height: 4),
          Text(
            'Tampilkan nasabah yang saldonya sedikitnya segini.',
            style: AppTextStyle.small.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final jumlah in _pilihan)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PencairanChip(
                      key: Key('saldo-pilihan-$jumlah'),
                      label: _singkat(jumlah),
                      selected: nilai == jumlah,
                      onTap: () => setState(() => _controller.text = '$jumlah'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('saldo-min-field'),
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            style: pencairanInputStyle,
            decoration:
                pencairanInputDecoration(hintText: 'Jumlah lain').copyWith(
              // An icon, not prefixText: that one hides until the field has text.
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Text('Rp', style: pencairanInputStyle),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: const Key('saldo-pratinjau'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: nilai > 0 && memenuhi == 0
                  ? Colors.red.shade50
                  : AppColors.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  nilai > 0 && memenuhi == 0
                      ? Icons.info_outline
                      : Icons.people_outline,
                  size: 18,
                  color: nilai > 0 && memenuhi == 0
                      ? Colors.red.shade700
                      : AppColors.greenDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nilai == 0
                        ? 'Isi jumlahnya untuk melihat siapa yang memenuhi.'
                        : memenuhi == 0
                            ? 'Belum ada nasabah dengan saldo '
                                '${rupiah(nilai)} ke atas.'
                            : '$memenuhi nasabah memenuhi '
                                '(saldo ${rupiah(nilai)} ke atas).',
                    style: AppTextStyle.small,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                key: const Key('terapkan-saldo-min'),
                onPressed: () => Navigator.of(context).pop(_nilai),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Terapkan'),
              ),
              const SizedBox(width: 12),
              TextButton(
                key: const Key('batal-saldo-min'),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.greenDark),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
