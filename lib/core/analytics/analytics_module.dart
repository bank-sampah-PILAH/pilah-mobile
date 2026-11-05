import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_client_factory.dart';
import 'package:pilah_mobile/core/analytics/analytics_config_secrets.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';

@module
abstract class AnalyticsModule {
  /// PostHog on the web when the build is configured for it, the no-op client
  /// everywhere else. Nothing records until something calls `start`.
  @lazySingleton
  AnalyticsClient analyticsClient() =>
      createAnalyticsClient(analyticsConfigFromSecrets());

  @lazySingleton
  AnalyticsConsentStore analyticsConsentStore(
    @Named('shared_preferences') AppStorage storage,
  ) =>
      AnalyticsConsentStore(storage);
}
