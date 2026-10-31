import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';

/// Keeps the entered search in sync with reset and responsive layout changes.
class NasabahSearchField extends ConsumerStatefulWidget {
  const NasabahSearchField({super.key});

  @override
  ConsumerState<NasabahSearchField> createState() => _NasabahSearchFieldState();
}

class _NasabahSearchFieldState extends ConsumerState<NasabahSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(nasabahProvider.notifier).searchQuery,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(nasabahProvider, (_, __) {
      final query = ref.read(nasabahProvider.notifier).searchQuery;
      if (_controller.text != query) {
        _controller.value = TextEditingValue(
          text: query,
          selection: TextSelection.collapsed(offset: query.length),
        );
      }
    });
    return CustomSearchField(
      controller: _controller,
      hintText: 'Cari nama nasabah...',
      onChanged: ref.read(nasabahProvider.notifier).searchNasabah,
    );
  }
}
