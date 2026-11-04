import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';

void main() {
  tearDown(() => dotenv.loadFromString(envString: '', isOptional: true));

  group('AnalyticsConfig.fromSecrets', () {
    test('is off when ENABLE_ANALYTICS is not set', () {
      dotenv.loadFromString(envString: '', isOptional: true);

      expect(AnalyticsConfig.fromSecrets(), isNull);
    });

    test('reads the key and environment, and defaults to the US host', () {
      dotenv.loadFromString(envString: '''
ENABLE_ANALYTICS=true
POSTHOG_API_KEY=phc_test_key
POSTHOG_ENVIRONMENT=staging
''');

      final config = AnalyticsConfig.fromSecrets();

      expect(config, isNotNull);
      expect(config!.apiKey, 'phc_test_key');
      expect(config.environment, 'staging');
      expect(config.host, 'https://us.i.posthog.com');
    });

    test('stays off when it is enabled but the key is missing', () {
      dotenv.loadFromString(envString: '''
ENABLE_ANALYTICS=true
POSTHOG_ENVIRONMENT=staging
''');

      expect(AnalyticsConfig.fromSecrets(), isNull);
    });

    test(
        'names a local build when no environment is set, so its events are '
        'never mistaken for staging or production', () {
      dotenv.loadFromString(envString: '''
ENABLE_ANALYTICS=true
POSTHOG_API_KEY=phc_test_key
''');

      expect(AnalyticsConfig.fromSecrets()!.environment, 'local');
    });
  });
}
