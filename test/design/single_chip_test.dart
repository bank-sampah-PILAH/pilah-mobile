import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A filter or choice pill is `AppChip`. The stock `ChoiceChip` and
/// `FilterChip` have their own shape, colours and 32 dp hit area, and two forms
/// that asked the same question (the metode of a pencairan) once used one each.
void main() {
  // The left boundary keeps `AppChip(` and `PencairanChip(` out of the count.
  final stock = RegExp(
    r'(?<![A-Za-z_])(ChoiceChip|FilterChip|InputChip|ActionChip|Chip)\(',
  );

  test('the pattern counts a stock chip but not the app chip', () {
    expect(stock.hasMatch('ChoiceChip(label: x)'), isTrue);
    expect(stock.hasMatch('child: FilterChip(label: x)'), isTrue);
    expect(stock.hasMatch('Chip(label: x)'), isTrue);
    expect(stock.hasMatch('AppChip(label: x)'), isFalse);
    expect(stock.hasMatch('PencairanChip(label: x)'), isFalse);
  });

  test('no screen builds a stock Material chip', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.startsWith('lib/design/')) continue;
      if (stock.hasMatch(entity.readAsStringSync())) offenders.add(entity.path);
    }

    expect(offenders, isEmpty,
        reason: 'Use AppChip (lib/design/widgets/app_chip.dart).');
  });
}
