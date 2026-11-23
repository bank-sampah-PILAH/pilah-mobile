import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';

/// A screen tells the screen recording what to show through
/// `core/privacy/replay_privacy.dart`. The code that decides how the recording
/// is made (`core/analytics/replay_masks.dart`) is for the analytics clients
/// only, so the design kit and the features do not depend on analytics.
void main() {
  test('only the analytics code imports the recording settings', () {
    final offenders = <String>[];
    for (final source in designSources()) {
      if (source.relativePath.startsWith('core/analytics/')) continue;
      if (source.read().contains('analytics/replay_masks.dart')) {
        offenders.add(source.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Import core/privacy/replay_privacy.dart for RevealInReplay, '
          'FixedText and HideInReplay.',
    );
  });
}
