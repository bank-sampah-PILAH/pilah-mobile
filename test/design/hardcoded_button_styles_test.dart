import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet against buttons styled per screen outside `lib/design/`.
///
/// `AppTheme` already gives every Material button the app's look, and
/// `AppButton` covers the red and grey variants, so a screen that writes its
/// own `styleFrom(...)` or `ButtonStyle(...)` is restyling a button the design
/// system already styles. New ones are not allowed; the existing ones are
/// recorded per file in `hardcoded_button_styles_baseline.json` and can only
/// go down.
///
/// After removing some, lower the baseline with
/// `UPDATE_BASELINE=1 flutter test test/design/hardcoded_button_styles_test.dart`.
const _baselinePath = 'test/design/hardcoded_button_styles_baseline.json';

final _override = RegExp(r'\bstyleFrom\(|\bButtonStyle\(');

Map<String, int> _scan() {
  final found = <String, int>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.startsWith('lib/design/')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _override.allMatches(entity.readAsStringSync()).length;
    if (count > 0) found[path] = count;
  }
  return found;
}

void main() {
  test('no screen adds a per-screen button style', () {
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

    final baseline = File(_baselinePath).existsSync()
        ? (jsonDecode(File(_baselinePath).readAsStringSync())
                as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int))
        : <String, int>{};

    final problems = <String>[];
    for (final entry in current.entries) {
      final allowed = baseline[entry.key] ?? 0;
      if (entry.value > allowed) {
        problems.add(
          '${entry.key}: ${entry.value} button style overrides, '
          'baseline allows $allowed',
        );
      }
    }

    expect(
      problems,
      isEmpty,
      reason: 'Use AppButton, or a plain Material button, which AppTheme '
          'already styles (see DESIGN.md). If a style is genuinely needed '
          'here, add the variant to AppButton instead of a per-screen '
          'override.',
    );
  });

  test('the baseline only lists files that still have overrides', () {
    if (!File(_baselinePath).existsSync()) return;
    final current = _scan();
    final baseline = (jsonDecode(File(_baselinePath).readAsStringSync())
            as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));

    final stale = baseline.entries
        .where((e) => (current[e.key] ?? 0) < e.value)
        .map((e) => '${e.key}: baseline ${e.value}, now ${current[e.key] ?? 0}')
        .toList();

    expect(
      stale,
      isEmpty,
      reason: 'Overrides were removed: lower the baseline with '
          'UPDATE_BASELINE=1 flutter test '
          'test/design/hardcoded_button_styles_test.dart.',
    );
  });
}
