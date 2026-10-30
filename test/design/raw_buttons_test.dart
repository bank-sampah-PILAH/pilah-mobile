import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ban on Material's filled and outlined buttons outside `lib/design/`.
///
/// `AppButton` is the one button of the app: it has the height, the radius,
/// the loading state and the variants (primary, outlined, neutral,
/// destructive, tonal ...). A screen that builds an `ElevatedButton`,
/// `OutlinedButton` or `FilledButton` gets its own look and its own states.
/// `TextButton` is still allowed for a quiet link-like action.
final _stock = RegExp(
  r'(?<![A-Za-z_])(ElevatedButton|OutlinedButton|FilledButton)(\.icon)?\(',
);

List<String> _scan() {
  final found = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.startsWith('lib/design/')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _stock.allMatches(entity.readAsStringSync()).length;
    if (count > 0) found.add('$path: $count');
  }
  return found;
}

void main() {
  test('the pattern counts the stock buttons but not AppButton', () {
    expect(_stock.hasMatch('child: ElevatedButton(onPressed: f)'), isTrue);
    expect(_stock.hasMatch('OutlinedButton.icon(onPressed: f)'), isTrue);
    expect(_stock.hasMatch('FilledButton(onPressed: f)'), isTrue);
    expect(_stock.hasMatch('AppButton(label: x)'), isFalse);
    expect(_stock.hasMatch('TextButton(onPressed: f)'), isFalse);
    expect(_stock.hasMatch('ElevatedButtonThemeData('), isFalse);
  });

  test('no screen builds a Material filled or outlined button', () {
    expect(
      _scan(),
      isEmpty,
      reason: 'Use AppButton (a variant, a size, an icon). If the design needs '
          'another look, add a variant to AppButton instead of styling a '
          'Material button in a screen.',
    );
  });
}
