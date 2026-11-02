import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';

void main() {
  test('NoopAnalyticsClient.start does nothing and completes', () async {
    await expectLater(NoopAnalyticsClient().start(), completes);
  });

  test('createAnalyticsClient returns the no-op client when analytics is off',
      () {
    expect(createAnalyticsClient(null), isA<NoopAnalyticsClient>());
  });

  test('createAnalyticsClient returns the no-op client outside the web', () {
    const config = AnalyticsConfig(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      environment: 'staging',
    );

    expect(createAnalyticsClient(config), isA<NoopAnalyticsClient>());
  });
}
