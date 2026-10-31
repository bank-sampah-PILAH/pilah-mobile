import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

/// Ban on choosing a font family outside `lib/design/`.
///
/// `AppTheme` sets Poppins as the default font and `AppTextStyle` and
/// `NasabahStyle` build on it, so a screen that writes `fontFamily: 'Roboto'`
/// or calls `GoogleFonts.inter(...)` is a screen in a different typeface. None
/// is allowed, and there is no baseline to hide behind.
final _family =
    RegExp(r'\bfontFamily\s*:|\bGoogleFonts\b|package:google_fonts/');

List<String> _scan() {
  final found = <String>[];
  for (final source in designSources()) {
    final path = source.path;
    if (source.inDesignKit || source.isGenerated) continue;
    final count = _family.allMatches(source.read()).length;
    if (count > 0) found.add('$path: $count font family choices');
  }
  return found;
}

void main() {
  test('the pattern catches every way of choosing a font family', () {
    expect(_family.hasMatch("TextStyle(fontFamily: 'Roboto')"), isTrue);
    expect(_family.hasMatch('fontFamily : name'), isTrue);
    expect(_family.hasMatch('GoogleFonts.inter(fontSize: 12)'), isTrue);
    expect(_family.hasMatch("import 'package:google_fonts/google_fonts.dart';"),
        isTrue);
    expect(_family.hasMatch('AppTextStyle.small'), isFalse);
    expect(_family.hasMatch('// the theme sets the font family'), isFalse);
  });

  test('no file outside lib/design chooses a font family', () {
    expect(
      _scan(),
      isEmpty,
      reason: 'Use AppTextStyle, NasabahStyle or the theme (Poppins). If the '
          'design needs another typeface, add it to lib/design/ instead of '
          'naming a family in a screen.',
    );
  });
}
