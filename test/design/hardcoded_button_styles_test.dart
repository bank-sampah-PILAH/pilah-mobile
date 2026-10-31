import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

/// Ban on buttons styled per screen outside `lib/design/`.
///
/// `AppTheme` already gives every Material button the app's look, and
/// `AppButton` covers the red and grey variants, so a screen that writes its
/// own `styleFrom(...)` or `ButtonStyle(...)` is restyling a button the design
/// system already styles. None is allowed, and there is no baseline to hide
/// behind.
final _override = RegExp(r'\bstyleFrom\(|\bButtonStyle\(');

List<String> _scan() {
  final found = <String>[];
  for (final source in designSources()) {
    final path = source.path;
    if (source.inDesignKit || source.isGenerated) continue;
    final count = _override.allMatches(source.read()).length;
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
