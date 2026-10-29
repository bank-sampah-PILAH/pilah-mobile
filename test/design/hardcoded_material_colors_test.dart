import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet against Flutter's stock palette used outside `lib/design/`.
///
/// `Colors.grey`, `Colors.black87` and `Colors.red` are not the colours of the
/// app: `Colors.grey` is #9E9E9E, 2.7:1 on white, which fails WCAG AA as text.
/// `AppColors` holds the palette that was checked for contrast. `Colors.white`
/// and `Colors.transparent` are fine. New stock colours are not allowed; the
/// existing ones are recorded per file in
/// `hardcoded_material_colors_baseline.json` and can only go down.
///
/// After removing some, lower the baseline with
/// `UPDATE_BASELINE=1 flutter test test/design/hardcoded_material_colors_test.dart`.
const _baselinePath = 'test/design/hardcoded_material_colors_baseline.json';

/// The left boundary keeps `AppColors.black` and `AppColors.grey100` out of the
/// count: only a bare `Colors.` is the stock palette.
final _stock = RegExp(
  r'(?<![A-Za-z_])Colors\.(grey|black|red|green|blue|orange|amber|teal|'
  r'yellow|purple|pink|indigo|brown|cyan|lime|deepOrange|lightBlue|'
  r'lightGreen|blueGrey|deepPurple)',
);

Map<String, int> _scan() {
  final found = <String, int>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.startsWith('lib/design/')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _stock.allMatches(entity.readAsStringSync()).length;
    if (count > 0) found[path] = count;
  }
  return found;
}

Map<String, int> _baseline() => File(_baselinePath).existsSync()
    ? (jsonDecode(File(_baselinePath).readAsStringSync())
            as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int))
    : <String, int>{};

void main() {
  test('the pattern counts the stock palette but not AppColors', () {
    expect(_stock.hasMatch('color: Colors.grey[500]'), isTrue);
    expect(_stock.hasMatch('Colors.black87'), isTrue);
    expect(_stock.hasMatch('color: Colors.red,'), isTrue);
    expect(_stock.hasMatch('AppColors.black'), isFalse);
    expect(_stock.hasMatch('AppColors.grey100'), isFalse);
    expect(_stock.hasMatch('color: Colors.white'), isFalse);
    expect(_stock.hasMatch('Colors.transparent'), isFalse);
  });

  test('no screen adds a stock Flutter colour', () {
    final current = _scan();

    if (Platform.environment['UPDATE_BASELINE'] == '1') {
      final sorted = Map.fromEntries(
        current.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      File(_baselinePath).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
      );
      return;
    }

    final baseline = _baseline();
    final problems = <String>[
      for (final entry in current.entries)
        if (entry.value > (baseline[entry.key] ?? 0))
          '${entry.key}: ${entry.value} stock colours, baseline allows '
              '${baseline[entry.key] ?? 0}',
    ];

    expect(
      problems,
      isEmpty,
      reason: 'Use AppRadius.sm, md, lg or xl '
          '(lib/design/constants/radius.dart). If the design needs a new '
          'step, add it there instead of writing a number in a screen.',
    );
  });

  test('the baseline only lists files that still use stock colours', () {
    final current = _scan();
    final stale = [
      for (final entry in _baseline().entries)
        if ((current[entry.key] ?? 0) < entry.value)
          '${entry.key}: baseline ${entry.value}, now ${current[entry.key] ?? 0}',
    ];

    expect(
      stale,
      isEmpty,
      reason: 'Stock colours were removed: lower the baseline with '
          'UPDATE_BASELINE=1 flutter test test/design/hardcoded_material_colors_test.dart.',
    );
  });
}
