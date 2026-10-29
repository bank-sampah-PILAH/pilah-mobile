import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet against style values hard-coded outside `lib/design/`.
///
/// Raw colours and font sizes in a screen drift apart between developers, so
/// new ones are not allowed: use `AppColors`, `AppTextStyle` or the theme. The
/// existing ones are recorded per file in `hardcoded_styles_baseline.json` and
/// can only go down.
///
/// After removing some, lower the baseline with
/// `UPDATE_BASELINE=1 flutter test test/design/hardcoded_styles_test.dart`.
const _baselinePath = 'test/design/hardcoded_styles_baseline.json';

final _color = RegExp(r'Color\(\s*0x[0-9A-Fa-f]{8}\s*\)|Color\.fromRGBO\(');
final _fontSize = RegExp(r'fontSize:\s*[0-9.]+');

Map<String, Map<String, int>> _scan() {
  final found = <String, Map<String, int>>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.startsWith('lib/design/')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final source = entity.readAsStringSync();
    final colors = _color.allMatches(source).length;
    final sizes = _fontSize.allMatches(source).length;
    if (colors > 0 || sizes > 0) {
      found[path] = {'color': colors, 'fontSize': sizes};
    }
  }
  return found;
}

void main() {
  test('no screen adds a hard-coded colour or font size', () {
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
            .map((k, v) => MapEntry(k, Map<String, int>.from(v as Map)))
        : <String, Map<String, int>>{};

    final problems = <String>[];
    for (final entry in current.entries) {
      final allowed = baseline[entry.key] ?? const {'color': 0, 'fontSize': 0};
      for (final kind in ['color', 'fontSize']) {
        final now = entry.value[kind]!;
        final before = allowed[kind] ?? 0;
        if (now > before) {
          problems.add('${entry.key}: $kind $now (allowed $before)');
        }
      }
    }

    expect(
      problems,
      isEmpty,
      reason:
          'Use AppColors / AppTextStyle / the theme instead of new literals.',
    );
  });
}
