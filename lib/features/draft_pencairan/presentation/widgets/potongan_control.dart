import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

import '../../domain/model/draft_pencairan.dart';
import 'pencairan_ui.dart';

/// Picks a potongan: percent (with a slider) or fixed rupiah. Keys are
/// `<keyPrefix>-persen`, `-rupiah`, `-nilai` and `-slider`.
class PotonganControl extends StatefulWidget {
  final String keyPrefix;
  final Potongan value;
  final ValueChanged<Potongan> onChanged;

  const PotonganControl({
    super.key,
    required this.keyPrefix,
    required this.value,
    required this.onChanged,
  });

  @override
  State<PotonganControl> createState() => _PotonganControlState();
}

class _PotonganControlState extends State<PotonganControl> {
  late final TextEditingController _controller =
      TextEditingController(text: _format(widget.value.nilai));

  static String _format(num nilai) =>
      nilai == nilai.truncate() ? '${nilai.truncate()}' : '$nilai';

  @override
  void didUpdateWidget(PotonganControl old) {
    super.didUpdateWidget(old);
    // Follow changes made elsewhere (the slider, the other jenis, a reset),
    // but never rewrite what the pengurus is typing.
    final typed = num.tryParse(_controller.text.replaceAll(',', '.'));
    if (typed != widget.value.nilai) {
      _controller.text = _format(widget.value.nilai);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setJenis(PotonganJenis jenis) {
    if (jenis == widget.value.jenis) return;
    // 10 percent and Rp 10 are nothing alike: start the new kind from zero.
    widget.onChanged(Potongan(jenis, 0));
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.keyPrefix;
    final persen = widget.value.jenis == PotonganJenis.persen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final jenis in PotonganJenis.values)
              PencairanChip(
                key: Key('$prefix-${jenis.name}'),
                label: jenis.label,
                selected: widget.value.jenis == jenis,
                onTap: () => _setJenis(jenis),
              ),
          ],
        ),
        if (persen)
          Slider(
            key: Key('$prefix-slider'),
            min: 0,
            max: 100,
            divisions: 200,
            activeColor: AppColors.greenDark,
            label: '${_format(widget.value.nilai)}%',
            value: widget.value.nilai.clamp(0, 100).toDouble(),
            onChanged: (value) =>
                widget.onChanged(Potongan(PotonganJenis.persen, value)),
          )
        else
          const SizedBox(height: 8),
        TextField(
          key: Key('$prefix-nilai'),
          controller: _controller,
          keyboardType: persen
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: [
            persen
                ? FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}'))
                : FilteringTextInputFormatter.digitsOnly,
          ],
          style: pencairanInputStyle,
          decoration: pencairanInputDecoration(
            hintText: persen ? 'Contoh: 10' : 'Contoh: 5000',
          ).copyWith(
            prefixText: persen ? null : 'Rp ',
            prefixStyle: pencairanInputStyle,
            suffixText: persen ? '%' : null,
          ),
          onChanged: (text) => widget.onChanged(Potongan(
            widget.value.jenis,
            num.tryParse(text.replaceAll(',', '.')) ?? 0,
          )),
        ),
      ],
    );
  }
}
