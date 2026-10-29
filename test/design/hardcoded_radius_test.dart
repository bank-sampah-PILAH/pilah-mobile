import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet against corner radii written as a number outside `lib/design/`.
///
/// `AppRadius` (8, 12, 16, 24) is the scale of the app, so a screen that writes
/// `BorderRadius.circular(14)` is inventing a shape the design does not have.
/// New ones are not allowed; the existing ones, mostly off-scale values such
/// as 10, 18 and 20, are recorded per file in
/// `hardcoded_radius_baseline.json` and can only go down.
///
/// After removing some, lower the baseline with
/// `UPDATE_BASELINE=1 flutter test test/design/hardcoded_radius_test.dart`.
const _baselinePath = 'test/design/hardcoded_radius_baseline.json';

/// `Radius.circular(` also covers `BorderRadius.circular(`. A token such as
/// `AppRadius.md` starts with a letter, so it is not counted.
final _literal = RegExp(r'Radius\.circular\(\s*[0-9]');

Map<String, int> _scan() {
  final found = <String, int>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.startsWith('lib/design/')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _literal.allMatches(entity.readAsStringSync()).length;
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
  test('the pattern counts a number but not a token', () {
    expect(_literal.hasMatch('BorderRadius.circular(12)'), isTrue);
    expect(_literal.hasMatch('Radius.circular( 24 )'), isTrue);
    expect(_literal.hasMatch('BorderRadius.circular(AppRadius.md)'), isFalse);
    expect(_literal.hasMatch('Radius.circular(AppRadius.xl)'), isFalse);
  });

  test('no screen adds a corner radius that is a bare number', () {
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
          '${entry.key}: ${entry.value} radii, baseline allows '
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

  test('the baseline only lists files that still have bare radii', () {
    final current = _scan();
    final stale = [
      for (final entry in _baseline().entries)
        if ((current[entry.key] ?? 0) < entry.value)
          '${entry.key}: baseline ${entry.value}, now ${current[entry.key] ?? 0}',
    ];

    expect(
      stale,
      isEmpty,
      reason: 'Radii were removed: lower the baseline with '
          'UPDATE_BASELINE=1 flutter test test/design/hardcoded_radius_test.dart.',
    );
  });
}
