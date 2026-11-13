import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

/// Ban on style values hard-coded outside `lib/design/`.
///
/// Raw colours and font sizes in a screen drift apart between developers, so
/// they are not allowed: use `AppColors`, `AppFontSize`, `AppTextStyle` or the
/// theme. Colours may be written in `lib/design/` (that is where the tokens
/// live); font sizes only in `lib/design/constants/font_size.dart`.

final _color = RegExp(
  r'Color\(\s*0x[0-9A-Fa-f]{8}\s*\)|Color\.(fromRGBO|fromARGB|from)\(',
);
final _fontSize = RegExp(r'fontSize:\s*[0-9.]+');

List<String> _scan() {
  final found = <String>[];
  for (final source in designSources()) {
    final path = source.path;
    if (path == 'lib/design/constants/font_size.dart') continue;
    if (source.isGenerated) continue;
    final text = source.read();
    final inDesign = source.inDesignKit;
    final colors = inDesign ? 0 : _color.allMatches(text).length;
    final sizes = _fontSize.allMatches(text).length;
    if (colors > 0) found.add('$path: $colors hard-coded colours');
    if (sizes > 0) found.add('$path: $sizes hard-coded font sizes');
  }
  return found;
}

void main() {
  test('the colour pattern catches every literal constructor', () {
    expect(_color.hasMatch('Color(0xFF112233)'), isTrue);
    expect(_color.hasMatch('Color.fromRGBO(1, 2, 3, 0.5)'), isTrue);
    expect(_color.hasMatch('Color.fromARGB(255, 1, 2, 3)'), isTrue);
    expect(_color.hasMatch('Color.from(alpha: 1, red: 0, green: 0, blue: 0)'),
        isTrue);
    expect(_color.hasMatch('AppColors.black'), isFalse);
  });

  test('no file hard-codes a colour or a font size', () {
    expect(
      _scan(),
      isEmpty,
      reason: 'Use AppColors, AppFontSize, AppTextStyle or the theme. If the '
          'design needs a new step, add it to lib/design/constants/ instead '
          'of writing a literal in a screen.',
    );
  });
}
