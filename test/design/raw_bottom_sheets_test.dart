import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps a bottom sheet from being opened by hand outside `lib/design/`.
///
/// On a phone a bottom sheet is right; in a browser one as wide as the window
/// is not. `showAdaptiveSurface` (forms, details), `showAdaptivePicker` and
/// `showAdaptiveConfirmation` pick the sheet on a phone and a dialog on a wide
/// window, so a screen that calls `showModalBottomSheet` itself skips that
/// choice.
///
/// Exempt: the demo login picker, which only exists in QA builds.
const _exempt = {
  'lib/features/authentication/presentation/widgets/demo_login_button.dart',
};

final _raw = RegExp(r'(?<![A-Za-z_])showModalBottomSheet\b');

void main() {
  test('the pattern counts a hand-opened sheet, not the adaptive helpers', () {
    expect(
        _raw.hasMatch('await showModalBottomSheet<int>(context: c)'), isTrue);
    expect(_raw.hasMatch('showAdaptiveSurface<int>(context, builder: b)'),
        isFalse);
    expect(_raw.hasMatch('showAdaptivePicker<int>(context: c)'), isFalse);
  });

  test('no screen opens a bottom sheet by hand', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.startsWith('lib/design/') || _exempt.contains(path)) continue;
      if (_raw.hasMatch(entity.readAsStringSync())) offenders.add(path);
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Use showAdaptiveSurface, showAdaptivePicker or '
          'showAdaptiveConfirmation (lib/design/layout/).',
    );
  });
}
