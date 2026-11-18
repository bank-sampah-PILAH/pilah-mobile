import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

/// Rupiah amounts are formatted by `CurrencyFormatter` only. About twenty
/// copies of the thousands-grouping loop used to live in screens, and one of
/// them was missing, which is how `Rp 3500` shipped.
void main() {
  test('no file outside CurrencyFormatter groups digits by hand', () {
    final grouping = [
      RegExp(r'%\s*3\s*==\s*0'),
      RegExp(r'\\d\{3\}'),
      RegExp(r'String\s+formatRupiahId'),
    ];
    final offenders = <String>[];
    for (final source in designSources()) {
      final path = source.path;
      if (path == 'lib/core/utils/formatter/currency_formatter.dart') {
        continue;
      }
      final text = source.read();
      if (grouping.any((re) => re.hasMatch(text))) offenders.add(path);
    }

    expect(offenders, isEmpty,
        reason: 'Use CurrencyFormatter.formatNumber / formatRupiah instead.');
  });
}
