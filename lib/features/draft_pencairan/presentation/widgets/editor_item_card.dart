import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

import '../../domain/model/draft_pencairan.dart';
import '../blocs/draft_editor_state.dart';
import 'draft_format.dart';
import 'pencairan_ui.dart';
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              Row(
                children: [
                  ElevatedButton(
                    key: const Key('terapkan-item'),
                    onPressed: () => Navigator.of(sheetContext)
                        .pop(_PotonganChoice(pilihan)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Terapkan'),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: TextButton(
                      onPressed: () => Navigator.of(sheetContext)
                          .pop(const _PotonganChoice(null)),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Ikuti potongan umum'),
                      ),
                    ),
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
    return PencairanCard.shadow(
      key: Key('item-${item.nasabahId}'),
      padding: const EdgeInsets.all(12),
      borderColor: error != null ? Colors.red.shade300 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PencairanAvatar(
                key: Key('avatar-${item.nasabahId}'),
                nama: item.nasabahNama,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nasabahNama,
                      style: AppTextStyle.headline3.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
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
              ],
              if (!readOnly) _menu(disesuaikan),
            ],
          ),
          const SizedBox(height: 12),
          if (readOnly)
            Text('Nominal ${rupiah(item.nominal)} · ${item.metode.label}',
                style: AppTextStyle.small)
          else ...[
            const SectionLabel.field('NOMINAL'),
            const SizedBox(height: 8),
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
                const SizedBox(width: 8),
                PencairanChip(
                  key: Key('penuh-${item.nasabahId}'),
                  label: 'Penuh',
                  selected: item.nominal == item.saldo,
                  onTap: () => onNominal(item.saldo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SectionLabel.field('METODE'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metode in MetodePencairan.values)
                  PencairanChip(
                    key: Key('metode-${item.nasabahId}-${metode.name}'),
                    label: metode.label,
                    selected: item.metode == metode,
                    onTap: () => onMetode(metode),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _HasilStrip(
            nasabahId: item.nasabahId,
            saldo: item.saldo,
            nominal: item.nominal,
            potongan: potongan,
            onEdit: readOnly ? null : () => _aturPotongan(context),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error,
                  style: AppTextStyle.small.copyWith(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _menu(bool disesuaikan) => PopupMenuButton<String>(
        key: Key('menu-item-${item.nasabahId}'),
        icon: Icon(Icons.more_vert, color: Colors.grey[800]),
        onSelected: (value) {
          if (value == 'reset') onReset();
          if (value == 'hapus') onRemove();
        },
        itemBuilder: (_) => [
          if (disesuaikan)
            const PopupMenuItem(
              value: 'reset',
              child: Text('Kembalikan ke default'),
            ),
          const PopupMenuItem(value: 'hapus', child: Text('Hapus dari draft')),
        ],
      );
}

/// Where the nasabah's card lands, top to bottom: the saldo they start from,
/// what comes off, and what is paid. A row for the nominal shows up only when
/// it differs from the saldo, so the figures always add up on screen.
class _HasilStrip extends StatelessWidget {
  final String nasabahId;
  final int saldo;
  final int nominal;
  final int potongan;

  /// Opens the potongan editor; null when the card is read-only.
  final VoidCallback? onEdit;

  const _HasilStrip({
    required this.nasabahId,
    required this.saldo,
    required this.nominal,
    required this.potongan,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row('Saldo awal', rupiah(saldo), Key('saldo-awal-$nasabahId')),
          if (nominal != saldo) ...[
            const SizedBox(height: 10),
            _row('Dicairkan', rupiah(nominal), Key('dicairkan-$nasabahId')),
          ],
          const SizedBox(height: 10),
          _row(
            'Potongan',
            potongan > 0 ? '\u2212 ${rupiah(potongan)}' : rupiah(potongan),
            Key('potongan-$nasabahId'),
            valueColor: potongan > 0 ? AppColors.statOrange : Colors.black87,
            trailing: onEdit == null ? null : _editButton(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.green.shade100),
          ),
          _row(
            'Dibayar',
            rupiah(nominal - potongan),
            Key('dibayar-$nasabahId'),
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _editButton() => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: InkWell(
          key: Key('potongan-item-$nasabahId'),
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_outlined,
                    size: 14, color: AppColors.greenDark),
                const SizedBox(width: 4),
                Text(
                  'Edit',
                  style: AppTextStyle.small.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _row(
    String label,
    String value,
    Key valueKey, {
    Color valueColor = Colors.black87,
    bool emphasized = false,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyle.small.copyWith(
            color: emphasized ? Colors.black87 : Colors.grey[700],
            fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
            fontSize: emphasized ? 15 : 13,
          ),
        ),
        if (trailing != null) trailing,
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              key: valueKey,
              style: AppTextStyle.title1.copyWith(
                fontSize: emphasized ? 20 : 15,
                fontWeight: emphasized ? FontWeight.bold : FontWeight.w600,
                color: emphasized ? const Color(0xFF006D44) : valueColor,
              ),
            ),
          ),
        ),
      ],
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
    final red = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    );
    final base = pencairanInputDecoration(hintText: 'Contoh: 50000');
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: pencairanInputStyle,
      decoration: base.copyWith(
        prefixText: 'Rp ',
        prefixStyle: pencairanInputStyle,
        enabledBorder: widget.hasError ? red : base.enabledBorder,
        focusedBorder: widget.hasError ? red : base.focusedBorder,
      ),
      onChanged: (text) => widget.onChanged(int.tryParse(text) ?? 0),
    );
  }
}
