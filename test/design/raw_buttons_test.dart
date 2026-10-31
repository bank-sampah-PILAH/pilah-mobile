import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

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
  for (final source in designSources()) {
    final path = source.path;
    if (source.inDesignKit || source.isGenerated) continue;
    final count = _stock.allMatches(source.read()).length;
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
