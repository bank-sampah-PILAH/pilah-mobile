import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

/// Ban on text fields decorated per screen outside `lib/design/`.
///
/// `appInputDecoration`, `appSearchDecoration` and
/// `appBorderlessInputDecoration` give every field of the app the same look,
/// so a screen that builds its own `InputDecoration(...)` is restyling a field
/// the design system already styles. None is allowed, and there is no baseline
/// to hide behind.

/// `\b` keeps `appInputDecoration(` from counting as a raw decoration.
final _raw = RegExp(r'\bInputDecoration\(');

Map<String, int> _scan() {
  final found = <String, int>{};
  for (final source in designSources()) {
    final path = source.path;
    if (source.inDesignKit || source.isGenerated) continue;
    final count = _raw.allMatches(source.read()).length;
    if (count > 0) found[path] = count;
  }
  return found;
}

void main() {
  test('the pattern counts a raw decoration but not the helpers', () {
    expect(_raw.hasMatch('decoration: InputDecoration(hintText: "x")'), isTrue);
    expect(_raw.hasMatch('appInputDecoration(hintText: "x")'), isFalse);
    expect(_raw.hasMatch('appSearchDecoration()'), isFalse);
  });

  test('no screen builds its own text field decoration', () {
    final problems = [
      for (final entry in _scan().entries)
        '${entry.key}: ${entry.value} decorations',
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
}
