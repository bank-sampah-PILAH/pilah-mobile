@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_client_factory.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';
import 'package:pilah_mobile/core/analytics/posthog_web_client.dart';

void main() {
  test('on the web, a configured build gets the PostHog client', () {
    const config = AnalyticsConfig(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      environment: 'staging',
    );

    expect(createAnalyticsClient(config), isA<PosthogWebClient>());
  });

  test('on the web, analytics that is off still gets the no-op client', () {
    expect(createAnalyticsClient(null), isA<NoopAnalyticsClient>());
  });
}
