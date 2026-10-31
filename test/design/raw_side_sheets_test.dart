import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

/// Keeps a side sheet from being opened by hand outside `lib/design/`.
///
/// `SideSheetPage` owns the whole container: where the panel sits, how wide it
/// is at this window width, the scrim, the slide, and the question it asks
/// before unsaved input is thrown away. A screen that reaches for
/// `showGeneralDialog` itself gets none of that, and the guard that matters
/// most is the last one — a panel that silently discards a half-typed setoran
/// is a bug the user cannot undo.
///
/// `endDrawer` is guarded for a different reason: it looks like the obvious
/// way to build this and it does not work here. The web shell builds a
/// different `Scaffold` per breakpoint and the narrow one already spends its
/// `drawer` on navigation, so an `endDrawer` is unreachable from the pages that
/// need it. That finding is worth keeping executable rather than only written
/// down.
const _exempt = <String>{};

final _raw = RegExp(r'(?<![A-Za-z_])(showGeneralDialog|endDrawer)\b');

void main() {
  test('the pattern counts a hand-opened panel, not the helper', () {
    expect(_raw.hasMatch('await showGeneralDialog<void>(context: c)'), isTrue);
    expect(_raw.hasMatch('Scaffold(endDrawer: Drawer())'), isTrue);
    expect(
      _raw.hasMatch('SideSheetPage<void>(child: form)'),
      isFalse,
    );
  });

  test('no screen opens a side sheet by hand', () {
    final offenders = <String>[];
    for (final source in designSources()) {
      final path = source.path;
      if (source.inDesignKit || _exempt.contains(path)) continue;
      if (_raw.hasMatch(source.read())) offenders.add(path);
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Use SideSheetPage (lib/design/layout/) as a declared route.',
    );
  });
}
