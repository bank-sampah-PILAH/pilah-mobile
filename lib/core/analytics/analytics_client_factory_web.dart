import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_config.dart';
import 'package:pilah_mobile/core/analytics/posthog_web_client.dart';

/// On the web a configured build sends events through PostHog's browser library.
AnalyticsClient createAnalyticsClient(AnalyticsConfig? config) {
  if (config == null) return NoopAnalyticsClient();
  return PosthogWebClient(apiKey: config.apiKey, host: config.host);
}
