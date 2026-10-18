import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet against dialogs built per screen outside `lib/design/`.
///
/// `AppDialog` (a question, or a form in a dialog), `AppIconDialog` (a decision
/// about a person or an item) and `showAppConfirmDialog` (a plain yes or no)
/// give every dialog the same title, the same buttons and the same radius. A
/// screen that builds its own `AlertDialog(...)` or `Dialog(...)` restyles all
/// three. New ones are not allowed; the existing ones are recorded per file in
/// `hardcoded_dialogs_baseline.json` and can only go down.
///
/// After removing some, lower the baseline with
/// `UPDATE_BASELINE=1 flutter test test/design/hardcoded_dialogs_test.dart`.
const _baselinePath = 'test/design/hardcoded_dialogs_baseline.json';

/// The left boundary keeps `showDialog(` and `SimpleDialog(` out of the count:
/// only the bare widgets are a dialog built by hand.
final _stock = RegExp(r'(?<![A-Za-z_])(AlertDialog|Dialog)\(');

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
  test('the pattern counts a dialog built by hand, not the helpers', () {
    expect(_stock.hasMatch('return AlertDialog(title: x)'), isTrue);
    expect(_stock.hasMatch('child: Dialog(child: x)'), isTrue);
    expect(_stock.hasMatch('showDialog(context: c)'), isFalse);
    expect(_stock.hasMatch('AppDialog(title: x)'), isFalse);
    expect(_stock.hasMatch('AppIconDialog(title: x)'), isFalse);
    expect(_stock.hasMatch('SimpleDialog(children: x)'), isFalse);
  });

  test('no screen builds a dialog by hand', () {
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
          '${entry.key}: ${entry.value} dialogs, baseline allows '
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

  test('the baseline only lists files that still build a dialog by hand', () {
    final current = _scan();
    final stale = [
      for (final entry in _baseline().entries)
        if ((current[entry.key] ?? 0) < entry.value)
          '${entry.key}: baseline ${entry.value}, now ${current[entry.key] ?? 0}',
    ];

    expect(
      stale,
      isEmpty,
      reason: 'Dialogs were removed: lower the baseline with '
          'UPDATE_BASELINE=1 flutter test test/design/hardcoded_dialogs_test.dart.',
    );
  });
}
