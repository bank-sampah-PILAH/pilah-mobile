@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/core/errors/error_reporter_factory.dart';
import 'package:pilah_mobile/core/errors/posthog_mobile_error_reporter.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('on Android and iOS errors go to the PostHog SDK', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;

      expect(createPlatformErrorReporter(), isA<PosthogMobileErrorReporter>());
    }
  });

  test('on any other platform nothing is reported', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    expect(createPlatformErrorReporter(), isA<NoopErrorReporter>());
  });
}
