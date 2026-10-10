import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// The sort button beside a search field: a grey square with a swap icon that
/// opens a white, rounded menu of the fields to order by. The menu stays open
/// after a choice, so a few orders can be tried in a row; it closes on a tap
/// elsewhere or on the button. The current field carries an arrow for its
/// direction.
class PencairanSortButton<T extends Enum> extends StatelessWidget {
  /// The menu is always this wide, whichever field is current, so it does not
  /// jump about as the arrow moves from row to row.
  static const _lebarMenu = 224.0;

  /// The button: a 24 icon with 14 padding all round.
  static const _lebarTombol = 52.0;

  /// What the menu keeps clear of the button's edge, which is the screen's
  /// edge beside a search field.
  static const _jarakTepi = 8.0;

  /// Room kept for the arrow, filled or not, so the labels line up.
  static const _lebarPanah = 20.0;

  final List<T> fields;
  final String Function(T field) labelOf;
  final T current;
  final bool ascending;
  final ValueChanged<T> onSort;

  /// Key of the button itself, and the prefix of each menu row's key.
  final Key buttonKey;
  final String itemKeyPrefix;

  const PencairanSortButton({
    super.key,
    required this.fields,
    required this.labelOf,
    required this.current,
    required this.ascending,
    required this.onSort,
    required this.buttonKey,
    required this.itemKeyPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      consumeOutsideTap: true,
      // The menu opens under the button with its right side pulled in from the
      // button's right edge, so it does not touch the edge of the screen.
      alignmentOffset:
          const Offset(-(_lebarMenu - _lebarTombol + _jarakTepi), 8),
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
        fixedSize: const WidgetStatePropertyAll(Size.fromWidth(_lebarMenu)),
      ),
      menuChildren: [
        for (final field in fields)
          MenuItemButton(
            key: Key('$itemKeyPrefix${field.name}'),
            closeOnActivate: false,
            onPressed: () => onSort(field),
            child: SizedBox(
              width: _lebarMenu - 32,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labelOf(field),
                      style: AppTextStyle.small.copyWith(
                        fontWeight: current == field
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _lebarPanah,
                    child: current == field
                        ? Icon(
                            ascending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 18,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: 'Urutkan',
        child: InkWell(
          key: buttonKey,
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
