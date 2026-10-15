import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';

import '../blocs/draft_editor_state.dart';
import '../blocs/editor_item_view.dart';
import 'pencairan_sort_button.dart';
import 'pencairan_ui.dart';

/// Search, sort and filter chips above the nasabah list of a long draft.
class EditorItemControls extends StatelessWidget {
  final DraftEditorState state;
  final TextEditingController search;
  final ItemFilter filter;
  final ItemSort sort;
  final ValueChanged<String> onSearch;
  final ValueChanged<ItemFilter> onFilter;
  final ValueChanged<ItemSortField> onSort;

  const EditorItemControls({
    super.key,
    required this.state,
    required this.search,
    required this.filter,
    required this.sort,
    required this.onSearch,
    required this.onFilter,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomSearchField(
                key: const Key('cari-nasabah'),
                hintText: 'Cari nama nasabah',
                controller: search,
                onChanged: onSearch,
              ),
            ),
            const SizedBox(width: 8),
            PencairanSortButton<ItemSortField>(
              buttonKey: const Key('urutkan-nasabah'),
              itemKeyPrefix: 'urut-',
              fields: ItemSortField.values,
              labelOf: (field) => field.label,
              current: sort.field,
              ascending: sort.ascending,
              onSort: onSort,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in ItemFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PencairanChip(
                    key: Key('filter-item-${f.name}'),
                    label: '${f.label} ${EditorItemView.hitung(state, f)}',
                    selected: filter == f,
                    onTap: () => onFilter(f),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
