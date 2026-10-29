import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet against text fields decorated per screen outside `lib/design/`.
///
/// `appInputDecoration`, `appSearchDecoration` and
/// `appBorderlessInputDecoration` give every field of the app the same look,
/// so a screen that builds its own `InputDecoration(...)` is restyling a field
/// the design system already styles. New ones are not allowed; the existing
/// ones are recorded per file in
/// `hardcoded_input_decoration_baseline.json` and can only go down.
///
/// After removing some, lower the baseline with
/// `UPDATE_BASELINE=1 flutter test test/design/hardcoded_input_decoration_test.dart`.
const _baselinePath = 'test/design/hardcoded_input_decoration_baseline.json';

/// `\b` keeps `appInputDecoration(` from counting as a raw decoration.
final _raw = RegExp(r'\bInputDecoration\(');

Map<String, int> _scan() {
  final found = <String, int>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.startsWith('lib/design/')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _raw.allMatches(entity.readAsStringSync()).length;
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
  test('no screen adds a per-screen text field decoration', () {
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
          '${entry.key}: ${entry.value} decorations, baseline allows '
              '${baseline[entry.key] ?? 0}',
    ];

    expect(
      problems,
      isEmpty,
      reason: 'Use appInputDecoration, appSearchDecoration or '
          'appBorderlessInputDecoration (lib/design/constants/form_style.dart). '
          'If a field genuinely needs another look, add it there instead of '
          'building an InputDecoration in a screen.',
    );
  });

  test('the baseline only lists files that still have decorations', () {
    final current = _scan();
    final stale = [
      for (final entry in _baseline().entries)
        if ((current[entry.key] ?? 0) < entry.value)
          '${entry.key}: baseline ${entry.value}, now ${current[entry.key] ?? 0}',
    ];

    expect(
      stale,
      isEmpty,
      reason: 'Decorations were removed: lower the baseline with '
          'UPDATE_BASELINE=1 flutter test '
          'test/design/hardcoded_input_decoration_test.dart.',
    );
  });
}
