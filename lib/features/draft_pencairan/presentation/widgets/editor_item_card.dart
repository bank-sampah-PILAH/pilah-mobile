import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import '../../domain/model/draft_pencairan.dart';
import '../blocs/draft_editor_state.dart';
import 'draft_format.dart';
import 'potongan_control.dart';

/// One nasabah in the editor: how much, how paid, and what comes off.
class EditorItemCard extends StatelessWidget {
  final EditorItem item;
  final DraftEditorState state;
  final bool readOnly;
  final ValueChanged<int> onNominal;
  final ValueChanged<MetodePencairan> onMetode;
  final ValueChanged<Potongan?> onPotongan;
  final VoidCallback onReset;
  final VoidCallback onRemove;

  const EditorItemCard({
    super.key,
    required this.item,
    required this.state,
    required this.readOnly,
    required this.onNominal,
    required this.onMetode,
    required this.onPotongan,
    required this.onReset,
    required this.onRemove,
  });

  Future<void> _aturPotongan(BuildContext context) async {
    var pilihan = item.potongan ?? state.potonganDefault;
    final hasil = await showModalBottomSheet<_PotonganChoice>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Potongan ${item.nasabahNama}',
                  style: AppTextStyle.headline3),
              const SizedBox(height: 12),
              PotonganControl(
                keyPrefix: 'item-potongan',
                value: pilihan,
                onChanged: (value) => setSheet(() => pilihan = value),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext)
                        .pop(const _PotonganChoice(null)),
                    child: const Text('Ikuti potongan umum'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext)
                        .pop(_PotonganChoice(pilihan)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Terapkan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (hasil != null) onPotongan(hasil.potongan);
  }

  @override
  Widget build(BuildContext context) {
    final error = state.errorFor(item);
    final potongan = state.potonganEfektif(item);
    final disesuaikan = state.disesuaikan(item);
    return Container(
      key: Key('item-${item.nasabahId}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: error != null ? Colors.red.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nasabahNama, style: AppTextStyle.headline3),
                    Text('Saldo ${rupiah(item.saldo)}',
                        style: AppTextStyle.extraSmall),
                  ],
                ),
              ),
              if (disesuaikan && !readOnly) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statOrangeLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Disesuaikan',
                      style: AppTextStyle.extraSmall
                          .copyWith(color: AppColors.statOrange)),
                ),
                IconButton(
                  key: Key('reset-${item.nasabahId}'),
                  tooltip: 'Kembalikan ke default',
                  icon: const Icon(Icons.restart_alt, size: 20),
                  onPressed: onReset,
                ),
              ],
              if (!readOnly)
                IconButton(
                  key: Key('hapus-${item.nasabahId}'),
                  tooltip: 'Hapus dari draft',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (readOnly)
            Text('Nominal ${rupiah(item.nominal)} · ${item.metode.label}',
                style: AppTextStyle.small)
          else ...[
            Row(
              children: [
                Expanded(
                  child: _NominalField(
                    fieldKey: Key('nominal-${item.nasabahId}'),
                    nominal: item.nominal,
                    hasError: error != null,
                    onChanged: onNominal,
                  ),
                ),
                TextButton(
                  key: Key('penuh-${item.nasabahId}'),
                  onPressed: () => onNominal(item.saldo),
                  child: const Text('Penuh'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final metode in MetodePencairan.values)
                  ChoiceChip(
                    key: Key('metode-${item.nasabahId}-${metode.name}'),
                    label: Text(metode.label),
                    selected: item.metode == metode,
                    selectedColor: AppColors.greenDark,
                    labelStyle: AppTextStyle.small.copyWith(
                      color: item.metode == metode
                          ? Colors.white
                          : AppColors.black,
                    ),
                    onSelected: (_) => onMetode(metode),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Potongan ${rupiah(potongan)}'
                  '${item.potongan == null ? ' (umum)' : ''}',
                  style: AppTextStyle.small,
                ),
              ),
              if (!readOnly)
                TextButton(
                  key: Key('potongan-item-${item.nasabahId}'),
                  onPressed: () => _aturPotongan(context),
                  child: const Text('Atur potongan'),
                ),
            ],
          ),
          Text(
            'Dibayar ${rupiah(item.nominal - potongan)}',
            style: AppTextStyle.small.copyWith(fontWeight: FontWeight.w600),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error,
                  style: AppTextStyle.small.copyWith(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}

class _PotonganChoice {
  /// Null means "follow the general potongan".
  final Potongan? potongan;

  const _PotonganChoice(this.potongan);
}

class _NominalField extends StatefulWidget {
  /// Goes on the [TextField] itself, so tests and finders reach the input.
  final Key fieldKey;
  final int nominal;
  final bool hasError;
  final ValueChanged<int> onChanged;

  const _NominalField({
    required this.fieldKey,
    required this.nominal,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_NominalField> createState() => _NominalFieldState();
}

class _NominalFieldState extends State<_NominalField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.nominal}');

  @override
  void didUpdateWidget(_NominalField old) {
    super.didUpdateWidget(old);
    // "Penuh" and reset change the nominal from outside; typing must not be
    // rewritten while the field already says the same number.
    if ((int.tryParse(_controller.text) ?? 0) != widget.nominal) {
      _controller.text = '${widget.nominal}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        isDense: true,
        labelText: 'Nominal',
        prefixText: 'Rp ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.hasError ? Colors.red : Colors.grey.shade400,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.hasError ? Colors.red : Colors.grey.shade400,
          ),
        ),
      ),
      onChanged: (text) => widget.onChanged(int.tryParse(text) ?? 0),
    );
  }
}
