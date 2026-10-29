import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ban on buttons styled per screen outside `lib/design/`.
///
/// `AppTheme` already gives every Material button the app's look, and
/// `AppButton` covers the red and grey variants, so a screen that writes its
/// own `styleFrom(...)` or `ButtonStyle(...)` is restyling a button the design
/// system already styles. New ones are not allowed; the existing ones are
/// recorded per file in `hardcoded_button_styles_baseline.json` and can only
/// go down.
final _override = RegExp(r'\bstyleFrom\(|\bButtonStyle\(');

List<String> _scan() {
  final found = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path;
    if (path.startsWith('lib/design/')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _override.allMatches(entity.readAsStringSync()).length;
    if (count > 0) found.add('$path: $count');
  }
  return found;
}

void main() {
  test('no screen uses a per-screen button style', () {
    expect(
      _scan(),
      isEmpty,
      reason:
          'Use AppButton (a variant, a size, an icon). If the design needs another look, add a variant to AppButton instead of styling a button in a screen.',
    );
  });
}
