import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ban on stock `FontWeight` values outside the font weight scale.
///
/// `AppFontWeight` (regular, medium, semibold and bold) is the set of faces
/// the app bundles, so a screen that writes `FontWeight.w600` or
/// `FontWeight.bold` is choosing a weight by number instead of by role. None
/// is allowed, and there is no baseline to hide behind.
///
/// The left boundary keeps `AppFontWeight.bold` out of the count: only a bare
/// `FontWeight.` is the stock value.
final _stock = RegExp(r'(?<![A-Za-z_])FontWeight\.(w[1-9]00|bold|normal)\b');

List<String> _scan() {
  final found = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path == 'lib/design/constants/font_weight.dart') continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _stock.allMatches(entity.readAsStringSync()).length;
    if (count > 0) found.add('$path: $count stock font weights');
  }
  return found;
}

void main() {
  test('the pattern counts a stock weight but not the token', () {
    expect(_stock.hasMatch('fontWeight: FontWeight.w600'), isTrue);
    expect(_stock.hasMatch('fontWeight: FontWeight.bold,'), isTrue);
    expect(_stock.hasMatch('FontWeight.normal'), isTrue);
    expect(_stock.hasMatch('fontWeight: AppFontWeight.bold'), isFalse);
    expect(_stock.hasMatch('FontWeight? weight'), isFalse);
  });

  test('no file writes a stock font weight', () {
    expect(
      _scan(),
      isEmpty,
      reason: 'Use AppFontWeight.regular, medium, semibold or bold '
          '(lib/design/constants/font_weight.dart). If the design needs a new '
          'weight, add it there, with its face bundled, instead of writing a '
          'stock value in a screen.',
    );
  });
}
