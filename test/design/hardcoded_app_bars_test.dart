import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet against a stock `AppBar(...)` built per screen outside `lib/design/`.
///
/// A page of the app is headed by `AppBackHeader` (Pengurus) or
/// `NasabahPageAppBar` (Nasabah), so a stock app bar with its own colours and
/// title is a page that looks unlike the others, as Edit Pencairan once did.
/// New ones are not allowed; the existing ones are recorded per file in
/// `hardcoded_app_bars_baseline.json` and can only go down.
///
/// After removing some, lower the baseline with
/// `UPDATE_BASELINE=1 flutter test test/design/hardcoded_app_bars_test.dart`.
const _baselinePath = 'test/design/hardcoded_app_bars_baseline.json';

/// The left boundary keeps `NasabahPageAppBar(` and `SliverAppBar(` out.
final _stock = RegExp(r'(?<![A-Za-z_])AppBar\(');

Map<String, int> _scan() {
  final found = <String, int>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path;
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
  test('the pattern counts a stock app bar, not the app ones', () {
    expect(_stock.hasMatch('appBar: AppBar(title: x)'), isTrue);
    expect(_stock.hasMatch('NasabahPageAppBar(title: x)'), isFalse);
    expect(_stock.hasMatch('SliverAppBar(title: x)'), isFalse);
  });

  test('no screen builds a stock app bar', () {
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
          '${entry.key}: ${entry.value} app bars, baseline allows '
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

  test('the baseline only lists files that still have a stock app bar', () {
    final current = _scan();
    final stale = [
      for (final entry in _baseline().entries)
        if ((current[entry.key] ?? 0) < entry.value)
          '${entry.key}: baseline ${entry.value}, now ${current[entry.key] ?? 0}',
    ];

    expect(
      stale,
      isEmpty,
      reason: 'App bars were removed: lower the baseline with '
          'UPDATE_BASELINE=1 flutter test test/design/hardcoded_app_bars_test.dart.',
    );
  });
}
