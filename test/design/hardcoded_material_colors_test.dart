import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ban on Flutter's stock palette used outside `lib/design/`.
///
/// `Colors.grey`, `Colors.black87` and `Colors.red` are not the colours of the
/// app: `Colors.grey` is #9E9E9E, 2.7:1 on white, which fails WCAG AA as text.
/// `AppColors` holds the palette that was checked for contrast. `Colors.white`
/// and `Colors.transparent` are fine, but `Colors.white70` and the other
/// translucent whites are stock values too. No file outside `lib/design/` may use a
/// stock colour, and there is no baseline to hide behind.

/// The left boundary keeps `AppColors.black` and `AppColors.grey100` out of the
/// count: only a bare `Colors.` is the stock palette.
final _stock = RegExp(
  r'(?<![A-Za-z_])Colors\.(grey|black|red|green|blue|orange|amber|teal|'
  r'yellow|purple|pink|indigo|brown|cyan|lime|deepOrange|lightBlue|'
  r'lightGreen|blueGrey|deepPurple|white[0-9])',
);

Map<String, int> _scan() {
  final found = <String, int>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path == 'lib/design/constants/colors.dart') continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _stock.allMatches(entity.readAsStringSync()).length;
    if (count > 0) found[path] = count;
  }
  return found;
}

void main() {
  test('the pattern counts the stock palette but not AppColors', () {
    expect(_stock.hasMatch('color: Colors.grey[500]'), isTrue);
    expect(_stock.hasMatch('Colors.black87'), isTrue);
    expect(_stock.hasMatch('color: Colors.red,'), isTrue);
    expect(_stock.hasMatch('AppColors.black'), isFalse);
    expect(_stock.hasMatch('AppColors.grey100'), isFalse);
    expect(_stock.hasMatch('Colors.white70'), isTrue);
    expect(_stock.hasMatch('Colors.white12'), isTrue);
    expect(_stock.hasMatch('color: Colors.white'), isFalse);
    expect(_stock.hasMatch('Colors.white,'), isFalse);
    expect(_stock.hasMatch('Colors.transparent'), isFalse);
  });

  test('no screen uses a stock Flutter colour', () {
    final problems = [
      for (final entry in _scan().entries)
        '${entry.key}: ${entry.value} stock colours',
    ];

    expect(
      problems,
      isEmpty,
      reason: 'Use a colour from AppColors (lib/design/constants/colors.dart). '
          'If the design needs a new one, add it there with its contrast '
          'checked instead of writing a stock colour in a screen.',
    );
  });
}
