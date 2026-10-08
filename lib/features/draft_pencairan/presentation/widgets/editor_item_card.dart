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
    return PencairanCard(
      key: Key('item-${item.nasabahId}'),
      padding: const EdgeInsets.all(12),
      borderColor: error != null ? Colors.red.shade300 : Colors.grey.shade200,
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
                    Text(
                      'Saldo ${rupiah(item.saldo)}',
                      style: AppTextStyle.small.copyWith(
                        color: Colors.grey[700],
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
                    icon: metode == MetodePencairan.tunai
                        ? Icons.payments_outlined
                        : Icons.account_balance_outlined,
                    selected: item.metode == metode,
                    onTap: () => onMetode(metode),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _HasilStrip(
            nasabahId: item.nasabahId,
            potongan: potongan,
            khusus: item.potongan != null,
            dibayar: item.nominal - potongan,
            onAtur: readOnly ? null : () => _aturPotongan(context),
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

/// Where the nasabah's card lands: what comes off, and what is paid.
class _HasilStrip extends StatelessWidget {
  final String nasabahId;
  final int potongan;
  final bool khusus;
  final int dibayar;

  /// Opens the potongan editor; null when the card is read-only.
  final VoidCallback? onAtur;

  const _HasilStrip({
    required this.nasabahId,
    required this.potongan,
    required this.khusus,
    required this.dibayar,
    required this.onAtur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel.field('POTONGAN'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            potongan > 0
                                ? '\u2212 ${rupiah(potongan)}'
                                : rupiah(potongan),
                            key: Key('potongan-$nasabahId'),
                            style: AppTextStyle.title1.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: potongan > 0
                                  ? AppColors.statOrange
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        khusus ? 'khusus' : 'umum',
                        style: AppTextStyle.extraSmall
                            .copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  if (onAtur != null)
                    TextButton.icon(
                      key: Key('potongan-item-$nasabahId'),
                      onPressed: onAtur,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                      icon: const Icon(Icons.percent, size: 16),
                      label: const Text('Atur potongan'),
                    ),
                ],
              ),
            ),
            VerticalDivider(width: 24, color: Colors.green.shade100),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel.field('DIBAYAR'),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      rupiah(dibayar),
                      key: Key('dibayar-$nasabahId'),
                      style: AppTextStyle.headline1.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF006D44),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
