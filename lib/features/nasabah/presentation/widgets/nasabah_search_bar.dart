import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/constants/nasabah_search.dart';

class NasabahSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const NasabahSearchBar({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: appSearchDecoration(hintText: nasabahSearchHint),
    );
  }
}
