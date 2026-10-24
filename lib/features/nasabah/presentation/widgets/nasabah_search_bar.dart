import 'package:flutter/material.dart';
// CI benchmark scratch: documentation comment only, no behavior change.
import 'package:pilah_mobile/design/constants/form_style.dart';

class NasabahSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const NasabahSearchBar({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: appSearchDecoration(hintText: 'Cari nama atau nomor...'),
    );
  }
}
