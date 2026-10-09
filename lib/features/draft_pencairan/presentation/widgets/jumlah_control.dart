import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/model/draft_pencairan.dart';
import 'pencairan_ui.dart';

/// Picks how much of each saldo everyone is paid: a share of it, or the same
/// rupiah. [value] is what the form holds now, or null when nothing is chosen;
/// a new Persen starts at 100, the whole saldo.
class JumlahControl extends StatefulWidget {
  final JumlahUmum? value;
  final ValueChanged<JumlahUmum> onChanged;

  const JumlahControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<JumlahControl> createState() => _JumlahControlState();
}

class _JumlahControlState extends State<JumlahControl> {
  late final TextEditingController _controller =
      TextEditingController(text: _format(widget.value));

  static String _format(JumlahUmum? value) {
    if (value == null || value.nilai == 0) return '';
    final nilai = value.nilai;
    return nilai == nilai.truncate() ? '${nilai.truncate()}' : '$nilai';
  }

  @override
  void didUpdateWidget(JumlahControl old) {
    super.didUpdateWidget(old);
    // Follow changes made elsewhere (a kind picked, an apply, a reset), but
    // never rewrite what is being typed.
    final typed = num.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    if (typed != (widget.value?.nilai ?? 0)) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pilih(JumlahJenis jenis) {
    if (widget.value?.jenis == jenis) return;
    // 50 percent and Rp 50 are nothing alike: start each kind afresh.
    widget.onChanged(
      jenis == JumlahJenis.persen ? JumlahUmum.penuh : JumlahUmum(jenis, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final persen = value?.jenis == JumlahJenis.persen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final jenis in JumlahJenis.values)
              PencairanChip(
                key: Key('jumlah-${jenis.name}'),
                label: jenis.label,
                selected: value?.jenis == jenis,
                onTap: () => _pilih(jenis),
              ),
          ],
        ),
        if (value != null) ...[
          const SizedBox(height: 8),
          TextField(
            key: const Key('jumlah-nilai'),
            controller: _controller,
            keyboardType: persen
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            inputFormatters: [
              persen
                  ? FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[.,]?\d{0,2}'))
                  : FilteringTextInputFormatter.digitsOnly,
            ],
            style: pencairanInputStyle,
            decoration: pencairanInputDecoration(
              hintText: persen ? 'Contoh: 50' : 'Contoh: 100000',
            ).copyWith(
              prefixText: persen ? null : 'Rp ',
              prefixStyle: pencairanInputStyle,
              suffixText: persen ? '% dari saldo' : 'paling banyak per nasabah',
            ),
            onChanged: (text) => widget.onChanged(JumlahUmum(
              value.jenis,
              num.tryParse(text.replaceAll(',', '.')) ?? 0,
            )),
          ),
        ],
      ],
    );
  }
}
