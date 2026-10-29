import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path == 'lib/core/utils/formatter/currency_formatter.dart') {
        continue;
      }
      final source = entity.readAsStringSync();
      if (grouping.any((re) => re.hasMatch(source))) offenders.add(path);
    }

    expect(offenders, isEmpty,
        reason: 'Use CurrencyFormatter.formatNumber / formatRupiah instead.');
  });
}
