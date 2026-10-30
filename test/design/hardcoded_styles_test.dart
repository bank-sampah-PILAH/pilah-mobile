import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path;
    if (path == 'lib/design/constants/font_size.dart') continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final source = entity.readAsStringSync();
    final inDesign = path.startsWith('lib/design/');
    final colors = inDesign ? 0 : _color.allMatches(source).length;
    final sizes = _fontSize.allMatches(source).length;
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
