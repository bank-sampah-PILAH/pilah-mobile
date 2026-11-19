@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/error_reporter_factory.dart';
import 'package:pilah_mobile/core/errors/posthog_web_error_reporter.dart';

void main() {
  test('on the web, errors go to the PostHog browser library', () {
    expect(createPlatformErrorReporter(), isA<PosthogWebErrorReporter>());
  });
}
