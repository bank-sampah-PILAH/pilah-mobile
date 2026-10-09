import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

import '../blocs/draft_editor_state.dart';
import '../blocs/editor_item_view.dart';
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
            _SortButton(sort: sort, onSort: onSort),
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

/// The sort menu. Unlike a popup menu it stays open after a choice, so a few
/// orders can be tried in a row; it closes on a tap elsewhere or on the button.
/// The sort menu. Unlike a popup menu it stays open after a choice, so a few
/// orders can be tried in a row; it closes on a tap elsewhere or on the button.
class _SortButton extends StatelessWidget {
  final ItemSort sort;
  final ValueChanged<ItemSortField> onSort;

  const _SortButton({required this.sort, required this.onSort});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      consumeOutsideTap: true,
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: const WidgetStatePropertyAll(Colors.black38),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      menuChildren: [
        for (final field in ItemSortField.values)
          MenuItemButton(
            key: Key('urut-${field.name}'),
            closeOnActivate: false,
            onPressed: () => onSort(field),
            trailingIcon: sort.field == field
                ? Icon(
                    sort.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 18,
                  )
                : null,
            child: Text(
              field.label,
              style: AppTextStyle.small.copyWith(
                fontWeight:
                    sort.field == field ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: 'Urutkan',
        child: InkWell(
          key: const Key('urutkan-nasabah'),
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.swap_vert, color: Colors.grey[800]),
          ),
        ),
      ),
    );
  }
}
