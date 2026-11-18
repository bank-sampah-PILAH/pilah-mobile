import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

/// Ban on a stock `AppBar(...)` built per screen outside `lib/design/`.
///
/// A page of the app is headed by `AppBackHeader` (Pengurus) or
/// `NasabahPageAppBar` (Nasabah), so a stock app bar with its own colours and
/// title is a page that looks unlike the others, as Edit Pencairan once did.
/// None is allowed, and there is no baseline to hide behind.
/// The left boundary keeps `NasabahPageAppBar(` and `SliverAppBar(` out.
final _stock = RegExp(r'(?<![A-Za-z_])AppBar\(');

List<String> _scan() {
  final found = <String>[];
  for (final source in designSources()) {
    final path = source.path;
    if (source.inDesignKit || source.isGenerated) continue;
    final count = _stock.allMatches(source.read()).length;
    if (count > 0) found.add('$path: $count');
  }
  return found;
}

void main() {
  test('the pattern counts a stock app bar, not the app ones', () {
    expect(_stock.hasMatch('appBar: AppBar(title: x)'), isTrue);
    expect(_stock.hasMatch('NasabahPageAppBar(title: x)'), isFalse);
    expect(_stock.hasMatch('SliverAppBar(title: x)'), isFalse);
  });

  test('no screen uses a stock AppBar', () {
    expect(
      _scan(),
      isEmpty,
      reason:
          'Use AppBackHeader or NasabahPageAppBar. If a page needs more (a subtitle, actions), add it to NasabahPageAppBar instead of building an AppBar in a screen.',
    );
  });
}
