import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_client_factory.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';

void main() {
  test('NoopAnalyticsClient.start does nothing and completes', () async {
    await expectLater(NoopAnalyticsClient().start(), completes);
  });

  test('NoopAnalyticsClient is not available and stop does nothing', () async {
    final client = NoopAnalyticsClient();

    expect(client.isAvailable, isFalse);
    await expectLater(client.stop(), completes);
  });

  test('NoopAnalyticsClient records no screen and leaves the app as it is', () {
    const app = SizedBox();

    expect(NoopAnalyticsClient().recordsScreen, isFalse);
    expect(NoopAnalyticsClient().wrapApp(app), same(app));
  });

  test('NoopAnalyticsClient ignores events and screens', () {
    final client = NoopAnalyticsClient();

    expect(() => client.capture('setoran_disimpan', {'jumlah_item': 2}),
        returnsNormally);
    expect(() => client.screen('dashboard'), returnsNormally);
    expect(() => client.screen('nasabah', {'layar_sebelumnya': 'dashboard'}),
        returnsNormally);
  });

  test('NoopAnalyticsClient ignores identity', () {
    final client = NoopAnalyticsClient();

    expect(() => client.identify('user-1'), returnsNormally);
    expect(() => client.register({'peran': 'pengelola'}), returnsNormally);
    expect(client.reset, returnsNormally);
  });

  test('createAnalyticsClient returns the no-op client when analytics is off',
      () {
    expect(createAnalyticsClient(null), isA<NoopAnalyticsClient>());
  });

  test('createAnalyticsClient returns the no-op client on a desktop', () {
    // Flutter's test platform is Android, which does get a native client.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const config = AnalyticsConfig(
      apiKey: 'phc_test_key',
      host: 'https://us.i.posthog.com',
      environment: 'staging',
    );

    expect(createAnalyticsClient(config), isA<NoopAnalyticsClient>());
  });

  test('the no-op client is one shared constant, not built again each time',
      () {
    expect(identical(createAnalyticsClient(null), createAnalyticsClient(null)),
        isTrue);
  });
}
